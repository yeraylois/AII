import json

from flask import Flask, request, jsonify
import subprocess
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

def run_playbook(extra_vars):
    try:
        result = subprocess.run(
            ['ansible-playbook', '-i', 'localhost,', '/app/green_playbook.yml', '--extra-vars', extra_vars],
            capture_output=True, text=True, check=True
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        if "Empty playbook, nothing to do" in e.stderr:
            return "No changes necessary (default configuration already applied)."
        else:
            raise


@app.route('/alert', methods=['POST'])
def alert():
    data = request.get_json(silent=True)
    app.logger.info("Alert received: %s", data)

    # VERIFY IF THE ALERT IS PostgreSQLDown
    alerts = data.get("alerts", [])
    for alert in alerts:
        if alert.get("labels", {}).get("alertname") == "PostgreSQLDown":
            try:
                output = run_playbook("alert=true")
                app.logger.info("Playbook fallback executed: %s", output)
                return jsonify({"status": "Fallback executed", "output": output}), 200
            except subprocess.CalledProcessError as e:
                app.logger.error("Error executing fallback, returncode=%s, stdout=%s, stderr=%s",
                                 e.returncode, e.stdout, e.stderr)
                return jsonify({
                    "status": "Error",
                    "rc": e.returncode,
                    "stdout": e.stdout,
                    "stderr": e.stderr
                }), 500

    app.logger.info("Alert does not match PostgreSQLDown; no action taken.")
    return jsonify({"status": "No action", "output": "Alert not related to PostgreSQLDown"}), 200

""""
@app.route('/reset', methods=['POST'])
def reset():
    data = request.get_json(silent=True)
    app.logger.info("Reset received: %s", data)
    try:
        # MANY EXTRA VARS TO THE PLAYBOOK:
        extra_vars = json.dumps({"reset": True, "alert": False})
        # -------------------------------

        output = run_playbook(extra_vars)
        app.logger.info("Playbook reset executed: %s", output)
        return jsonify({"status": "Reset executed", "output": output}), 200
    except subprocess.CalledProcessError as e:
        app.logger.error("Error executing reset, returncode=%s, stdout=%s, stderr=%s",
                         e.returncode, e.stdout, e.stderr)
        return jsonify({
            "status": "Error",
            "rc": e.returncode,
            "stdout": e.stdout,
            "stderr": e.stderr
        }), 500
    
"""

@app.route('/reset', methods=['POST'])
def reset():
    data = request.get_json(silent=True)
    app.logger.info("Reset received: %s", data)
    alerts = data.get("alerts", [])
    for alert in alerts:
        if alert.get("labels", {}).get("alertname") == "MySQLDown":
            try:
                # Ejecuta el playbook para restablecer el entorno (MySQLDown)
                extra_vars = json.dumps({"reset": True, "alert": False})
                output = run_playbook(extra_vars)
                app.logger.info("Playbook reset executed: %s", output)
                return jsonify({"status": "Reset executed", "output": output}), 200
            except subprocess.CalledProcessError as e:
                app.logger.error("Error executing reset, returncode=%s, stdout=%s, stderr=%s",
                                 e.returncode, e.stdout, e.stderr)
                return jsonify({
                    "status": "Error",
                    "rc": e.returncode,
                    "stdout": e.stdout,
                    "stderr": e.stderr
                }), 500

    app.logger.info("Reset alert does not match MySQLDown; no action taken.")
    return jsonify({"status": "No action", "output": "Alert not related to MySQLDown"}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)