from fastapi import FastAPI, Request
from fastapi.templating import Jinja2Templates

app = FastAPI()
templates = Jinja2Templates(directory="/code")

@app.get("/")
def home(request: Request):
    return templates.TemplateResponse("form.html", {"request": request})