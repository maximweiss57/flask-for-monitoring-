FROM python:slim
WORKDIR /monitoring_app
COPY . /monitoring_app
RUN pip install -r requirements.txt
ENV MONGODB_HOST = mongodb
EXPOSE 5000
CMD ["python", "run.py"]