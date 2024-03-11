FROM python:slim
WORKDIR /monitoring_app
COPY . /monitoring_app
RUN pip install -r requirements.txt
EXPOSE 5000
CMD ["python", "app.py"]