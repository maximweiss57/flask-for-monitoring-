FROM python:slim
WORKDIR /monitoring_app
COPY . /monitoring_app
RUN pip install -r requirements.txt
EXPOSE 8080
CMD ["python", "run.py"]