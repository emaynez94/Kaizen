from flask import Flask, render_template


app = Flask(__name__, template_folder=".")


@app.route("/")
def tracker():
    return render_template("index.html")


@app.route("/kaizen/<int:id>")
def details(id):
    return render_template("details.html", id=id)


if __name__ == "__main__":
    app.run(debug=True)
