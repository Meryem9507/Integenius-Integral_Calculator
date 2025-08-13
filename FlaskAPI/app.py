import os
import logging
from flask import Flask, request, jsonify, abort
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_limiter.errors import RateLimitExceeded
import redis
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

# Logging configuration
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

# ----------------- TOKEN -----------------
API_TOKEN = os.environ.get("API_TOKEN", "SECRET_TOKEN_647597")

def token_required(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')
        token = auth_header.split(" ")[1] if auth_header.startswith("Bearer ") else None
        if not token or token != API_TOKEN:
            abort(401, description="Unauthorized: Token is missing or invalid.")
        return f(*args, **kwargs)
    return decorated

# ----------------- RATE LIMITER -----------------
REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/0")
try:
    limiter_storage = Limiter(
        key_func=get_remote_address,
        default_limits=["200 per day", "50 per hour"],
        storage_uri=REDIS_URL
    )
    limiter_storage.init_app(app)
    logging.info(f"Limiter using Redis storage at {REDIS_URL}")
except Exception as e:
    logging.warning(f"Redis not available ({REDIS_URL}), falling back to in-memory limiter. Error: {e}")
    limiter_storage = Limiter(key_func=get_remote_address, default_limits=["200 per day", "50 per hour"])
    limiter_storage.init_app(app)

@app.errorhandler(RateLimitExceeded)
def rate_limit_handler(e):
    return jsonify(error="Rate limit exceeded", message=str(e.description)), 429

# ----------------- SYMPY SETUP -----------------
x = symbols('x', real=True)
transformations = standard_transformations + (implicit_multiplication_application,)
local_dict = {
    "x": x, "sin": sin, "cos": cos, "tan": tan, "cot": cot,
    "sec": sec, "csc": csc, "atan": atan, "asin": asin, "acos": acos,
    "log": log, "ln": log, "exp": exp, "pi": pi, "e": E, "E": E,
    "sqrt": sqrt, "abs": Abs, "oo": oo
}

# ----------------- UTILITY FUNCTIONS -----------------
def parse_limit(limit_str: str):
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
    try:
        result = integrate(expr, (var, lower, upper)) if lower is not None and upper is not None else integrate(expr, var)
        return simplify(result)
    except Exception as e:
        logging.warning(f"Integration error: {e}")
        return None

def latex_ln(expr):
    latex_str = latex(expr)
    return latex_str.replace(r'\log', r'\ln')

# ----------------- ROUTES -----------------
@app.route('/')
@limiter_storage.limit("20 per minute")
def home():
    user_agent = request.headers.get('User-Agent', '').lower()
    remote_addr = request.remote_addr
    health_check_indicators = ['go-http-client', 'uptimerobot', 'pingdom', 'monitor', 'health', 'check']
    if remote_addr == '127.0.0.1' or any(indicator in user_agent for indicator in health_check_indicators):
        return {"status": "healthy", "message": "API is running"}, 200
    token = request.headers.get('Authorization', '').split(" ")[1] if request.headers.get('Authorization', '').startswith("Bearer ") else None
    if token != API_TOKEN:
        abort(401, description="Unauthorized: Token is missing or invalid.")
    return {"status": "authenticated", "message": "API is running with valid token"}

@app.route("/calculate", methods=["POST"])
@limiter_storage.limit("10 per minute")
@token_required
def calculate_integral():
    try:
        data = request.get_json(force=True)
        function_str = data.get("function", "").strip()
        lower_limit = parse_limit(data.get("lower_limit", "").strip())
        upper_limit = parse_limit(data.get("upper_limit", "").strip())
        function_str = function_str.replace("ln(", "log(")
        if not function_str:
            return jsonify(success=False, error="The function cannot be empty.", steps=[], methods=[]), 400
        try:
            expr = parse_expr(function_str, transformations=transformations, local_dict=local_dict)
        except Exception:
            return jsonify(success=False, error="Function not understood. Check spelling.", steps=[], methods=[]), 400

        steps = [f"Integrand: {latex_ln(expr)}", f"Simplified integrand: {latex_ln(simplify(expr))}"]
        indefinite_integral = safe_integrate(expr, x)
        if indefinite_integral is None:
            steps.append("The indefinite integral could not be solved analytically.")
            return jsonify(success=False, error="No analytical solution found.", steps=steps, methods=[]), 400

        steps.append(f"Indefinite integral: {latex_ln(indefinite_integral)} + C")
        if lower_limit is not None and upper_limit is not None:
            definite_integral = safe_integrate(expr, x, lower_limit, upper_limit)
            if definite_integral is None:
                steps.append("The definite integral could not be calculated.")
                return jsonify(success=False, error="The definite integral could not be calculated.", steps=steps, methods=[]), 400
            return jsonify(success=True, result=latex_ln(definite_integral), steps=steps, methods=[], is_definite=True, is_improper=False)

        return jsonify(success=True, result=latex_ln(indefinite_integral) + " + C", steps=steps, methods=[], is_definite=False, is_improper=False)

    except Exception as e:
        traceback_str = traceback.format_exc()
        logging.error(f"Error: {e}\n{traceback_str}")
        return jsonify(success=False, error=f"Server error: {str(e)}", steps=[f"Error: {str(e)}"], methods=[]), 500

# ----------------- MAIN -----------------
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    # Dev server for local testing; for prod, run via gunicorn
    app.run(host="0.0.0.0", port=port)

