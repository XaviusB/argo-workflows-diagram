FROM ubuntu:focal

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-setuptools \
    python3-wheel \
    python3-venv \
    graphviz graphviz-dev \
    && mkdir /app && \
    rm -rf /var/lib/apt/lists/*

ADD requirements.txt /app/requirements.txt

WORKDIR /app

RUN pip install -r requirements.txt

ADD tree.py /app/tree.py

RUN useradd -ms /bin/bash appuser \
  && chown -R appuser:appuser /app \
  && chmod 500 /app/tree.py
USER appuser

ENTRYPOINT ["python3", "tree.py"]
