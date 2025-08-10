import os
import logging
from flask import Flask, request, jsonify, abort
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_cors import CORS
from sympy import (
    symbols, sin, cos, tan, cot, sec, csc, atan, asin, acos,
    log, exp, pi, E, sqrt, Abs, integrate, oo, simplify, latex,
    Rational
)
from sympy.parsing.sympy_parser import parse_expr, standard_transformations, implicit_multiplication_application
import traceback

app = Flask(__name__)
CORS(app)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s',
    handlers=[
        logging.FileHandler("flask_app.log"),
        logging.StreamHandler()
    ]
)

@app.before_request
def log_request_info():
    logging.info(f"Request from {request.remote_addr} to {request.method} {request.path}")

@app.after_request
def log_response_info(response):
    logging.info(f"Response status: {response.status} for {request.method} {request.path} from {request.remote_addr}")
    return response


API_TOKEN = "SECRET_TOKEN_647597"

def token_required(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        auth_header = request.headers.get('Authorization')
        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header.split(" ")[1]
        if not token or token != API_TOKEN:
            abort(401, description="Unauthorized: Token is missing or invalid.")
        return f(*args, **kwargs)
    return decorated

limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["100 per hour"]  
)
limiter.init_app(app)
 

@app.route('/')
@token_required
@limiter.limit("20 per minute")
def home():
    return "API is running!"


# We define the variable x as a real number
x = symbols('x', real=True)

# Transformations to enable SymPy's automatic multiplication detection
transformations = standard_transformations + (implicit_multiplication_application,)

# Functions and constants to be used in parse operations
local_dict = {
    "x": x, "sin": sin, "cos": cos, "tan": tan, "cot": cot,
    "sec": sec, "csc": csc, "atan": atan, "asin": asin, "acos": acos,
    "log": log, "ln": log, "exp": exp, "pi": pi, "e": E, "E": E,
    "sqrt": sqrt, "abs": Abs, "oo": oo
}

def parse_limit(limit_str: str):
    """Parses the limit value safely."""
    if not limit_str:
        return None
    s = limit_str.strip().lower()
    if s in ['oo', '∞', 'infinity', '+oo', '+∞']:
        return oo
    elif s in ['-oo', '-∞', '-infinity']:
        return -oo
    elif s == 'e':
        return E
    elif s == 'pi':
        return pi
    else:
        try:
            return parse_expr(limit_str, transformations=transformations, local_dict=local_dict)
        except Exception:
            try:
                return float(limit_str)
            except ValueError:
                return None

def safe_integrate(expr, var, lower=None, upper=None):
    """Calculates the integral safely. If there is an error, None is returned."""
    try:
        if lower is not None and upper is not None:
            result = integrate(expr, (var, lower, upper))
        else:
            result = integrate(expr, var)
        return simplify(result)
    except Exception as e:
        print(f"Integration error: {e}")
        return None

def latex_ln(expr):
    """SymPy latex changes the output of log() functions to ln."""
    latex_str = latex(expr)
    return latex_str.replace(r'\log', r'\ln')

def detect_integration_methods(function_str, expr, indefinite_integral):
    """
    Attempts to identify integration methods from function expression.
    Some methods are derived based on simple patterns.
    """
    methods = []
    function_lower = function_str.lower()

    trig_patterns = ['sin', 'cos', 'tan', 'sec', 'csc', 'cot']
    if any(pattern in function_lower for pattern in trig_patterns):
        if 'sqrt' in function_lower and ('+' in function_lower or '-' in function_lower):
            methods.append('Trigonometric Substitution')
        elif sum(1 for pattern in trig_patterns if pattern in function_lower) >= 2:
            methods.append('Trigonometric Identities')

    if ('log' in function_lower or 'ln' in function_lower) and 'x' in function_lower:
        methods.append('Integration by Parts')
    elif 'x' in function_lower and any(func in function_lower for func in ['sin', 'cos', 'exp', 'e^']):
        if any(pattern in function_lower for pattern in ['x*sin', 'x*cos', 'x*exp', 'x*e^']):
            methods.append('Integration by Parts')

    if '/' in function_str:
        try:
            if function_str.count('/') == 1:
                denominator = function_str.split('/')[1].strip()
                if ('x^2' in denominator or 'x**2' in denominator) or '(' in denominator:
                    methods.append('Partial Fractions')
        except Exception:
            pass

    composite_indicators = [
        ('log', ['/', 'x']),
        ('sin', ['cos']),
        ('cos', ['sin']),
        ('exp', ['x']),
        ('sqrt', ['x']),
    ]
    for main_func, indicators in composite_indicators:
        if main_func in function_lower:
            if any(ind in function_lower for ind in indicators):
                if 'U-Substitution' not in methods:
                    methods.append('U-Substitution')
                break

    if ('(' in function_str and ')' in function_str) and 'x' in function_lower:
        if any(func in function_lower for func in ['sin(', 'cos(', 'exp(', 'log(']):
            if 'U-Substitution' not in methods and 'Integration by Parts' not in methods:
                methods.append('U-Substitution')

    return methods

@app.route("/calculate", methods=["POST"])
def calculate_integral():
    try:
        data = request.get_json(force=True)
        print("Incoming request JSON:", data)

        function_str = data.get("function", "")
        function_str = function_str.strip() if isinstance(function_str, str) else ""

        lower_limit_raw = data.get("lower_limit")
        lower_limit_str = lower_limit_raw.strip() if isinstance(lower_limit_raw, str) else ""

        upper_limit_raw = data.get("upper_limit")
        upper_limit_str = upper_limit_raw.strip() if isinstance(upper_limit_raw, str) else ""

        # We replace ln expression with log for SymPy
        function_str = function_str.replace("ln(", "log(")

        if not function_str:
            return jsonify(success=False, error="The function cannot be empty.", steps=[], methods=[]), 400

        # Parse the function.
        try:
            expr = parse_expr(function_str, transformations=transformations, local_dict=local_dict)
        except Exception:
            return jsonify(success=False, error="Function not understood. Check spelling.", steps=[], methods=[]), 400

        # Parse the limits.
        lower_limit = parse_limit(lower_limit_str) if lower_limit_str else None
        upper_limit = parse_limit(upper_limit_str) if upper_limit_str else None

        steps = []
        steps.append(f"Integrand: {latex_ln(expr)}")

        simplified_expr = simplify(expr)
        steps.append(f"Simplified integrand: {latex_ln(simplified_expr)}")

        # Indefinite integral
        indefinite_integral = safe_integrate(simplified_expr, x)
        if indefinite_integral is None:
            steps.append("The indefinite integral could not be solved analytically.")
            return jsonify(
                success=False,
                error="No analytical solution found.",
                steps=steps,
                methods=[]
            ), 400
        
        steps.append(f"Indefinite integral: {latex_ln(indefinite_integral)} + C")

        # Method determination
        methods = detect_integration_methods(function_str, simplified_expr, indefinite_integral)

        # Check for definite integral
        is_improper = False
        if lower_limit is not None and upper_limit is not None:
            is_improper = (lower_limit == oo or lower_limit == -oo or upper_limit == oo or upper_limit == -oo)
            steps.append(f"Belirli integral hesaplanıyor: \\int_{{{latex_ln(lower_limit)}}}^{{{latex_ln(upper_limit)}}} {latex_ln(simplified_expr)} \\, dx")
            definite_integral = safe_integrate(simplified_expr, x, lower_limit, upper_limit)

            if definite_integral is None:
                steps.append("The definite integral could not be calculated.")
                return jsonify(
                    success=False,
                    error="The definite integral could not be calculated.",
                    steps=steps,
                    methods=methods
                ), 400

            simplified_result = simplify(definite_integral)
            steps.append(f"Sonuç: {latex_ln(simplified_result)}")

            return jsonify(
                success=True,
                result=latex_ln(simplified_result),
                steps=steps,
                methods=methods,
                is_definite=True,
                is_improper=is_improper
            )

        # Indefinite integral result
        return jsonify(
            success=True,
            result=latex_ln(indefinite_integral) + " + C",
            steps=steps,
            methods=methods,
            is_definite=False,
            is_improper=False
        )

    except Exception as e:
        traceback_str = traceback.format_exc()
        print(f"Error: {e}\n{traceback_str}")
        return jsonify(
            success=False,
            error=f"Server error: {str(e)}",
            steps=[f"Error: {str(e)}"],
            methods=[]
        ), 500


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=int(os.environ.get("PORT", 8080)))