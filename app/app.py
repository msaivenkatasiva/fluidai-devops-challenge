from flask import Flask, jsonify
import redis
import os

app = Flask(__name__)

redis_host = os.environ.get('REDIS_HOST', 'redis-service')
r = redis.Redis(host=redis_host, port=6379)

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

@app.route('/ready')
def ready():
    try:
        r.ping()
        return jsonify({"status": "ready"})
    except:
        return jsonify({"status": "not ready"}), 503

@app.route('/')
def index():
    count = r.incr('visits')
    return jsonify({
        "message": "Fluid AI DevOps Challenge",
        "visits": int(count)
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)