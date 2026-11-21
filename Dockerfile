FROM python:3.12-alpine AS builder
WORKDIR /build
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-alpine
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PORT=5000
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app/app.py app/config.py ./
COPY app/templates ./templates
RUN apk upgrade --no-cache && addgroup -g 10001 -S app && adduser -u 10001 -S -G app app
USER 10001:10001
EXPOSE 5000
HEALTHCHECK --interval=15s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health')"
CMD ["gunicorn","--bind","0.0.0.0:5000","--workers","2","--worker-tmp-dir","/tmp","app:app"]
