FROM ubuntu:latest
RUN apt-get update && apt-get install -y python3 python3-pip
FROM python:3.8
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt
ENV PATH="$PATH:$HOME/.local/bin"
CMD ["uvicorn","main:app", "--host","0.0.0.0","--port","5000"]
EXPOSE 5000