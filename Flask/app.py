from flask import Flask
import requests

ESURL = 'http://elasticsearch:9200'

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hey, we have Flask in a Docker container!'

@app.route('/escheck', methods = ['GET'])
def es_check():
    r = requests.get(ESURL)    
    return 'Hey, Flask can talk to ElasticSearch!\nResponse is {}'.format(r.content)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

