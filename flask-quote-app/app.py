from flask import Flask, render_template_string
import boto3
import json

app = Flask(__name__)

AWS_REGION = 'us-west-2'
MODEL_ID = 'amazon.titan-text-express-v1'

# Initiate Bedrock runtime client
bedrock = boto3.client(
        service_name='bedrock-runtime',
        region_name=AWS_REGION
)

def get_ai_quote():
    """ Calls Bedrock to generate an insiprational quote. """

    prompt = "Generate a single, short, inspirational quote about persistence, hard work, or achieving goals. Do not include the author or any introductory phrases like 'The quote is: '."

    body = json.dumps({
        "inputText": prompt,
        "textGenerationConfig": {
            "maxTokenCount": 60, # max characters for quote
            "temperature": 0.8,
            "topP": 0.9
        }
    })

    try:
        # call model
        response = bedrock.invoke_model(
            body=body,
            modelId=MODEL_ID,
            accept='application/json',
            contentType='application/json'
        )

        # parse response body
        response_body = json.loads(response.get('body').read())

        # Extract quote from Titan JSON response structure
        quote = response_body.get('results')[0].get('outputText').strip()

        return quote
    
    except Exception as e:
        print(f"Error calling Bedrock: {e}")
        return "API error"
    
@app.route('/')
def home():
    """The main route that fetches the quote and renders HTML."""
    ai_quote = get_ai_quote()

    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>AI Quote Service</title>
        <style>
            body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f9; color: #333; }}
            .container {{ width: 80%; margin: 50px auto; padding: 30px; background: white; box-shadow: 0 4px 8px rgba(0,0,0,0.1); border-radius: 12px; }}
            h1 {{ color: #007bff; border-bottom: 2px solid #eee; padding-bottom: 10px; }}
            .quote {{ font-size: 1.8em; font-style: italic; margin: 30px 0; color: #555; line-height: 1.4; }}
            .footer {{ margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; font-size: 0.9em; color: #777; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>AI Wisdom of the Day!!!</h1>
            <p class="quote">"{ai_quote}"</p>
            <div class="footer">
                Generated dynamically by the <strong>Amazon Bedrock (Titan Express)</strong> LLM.
            </div>
        </div>
    </body>
    </html>
    """
    return render_template_string(html_content)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
