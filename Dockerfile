FROM condaforge/miniforge3:latest

ARG PYTHON_VERSION=3.12
ARG ENV_NAME=app

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Create a dedicated conda environment with Python
RUN mamba create -y -n ${ENV_NAME} python=${PYTHON_VERSION} \
    && conda clean -afy

# Put the environment first on PATH so python/pip/streamlit resolve to it
ENV PATH=/opt/conda/envs/${ENV_NAME}/bin:$PATH \
    CONDA_DEFAULT_ENV=${ENV_NAME}

WORKDIR /app

# Install dependencies first so this layer is cached across code changes
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy the rest of the project
COPY . .

# Run as a non-root user
RUN useradd --create-home --uid 1000 appuser \
    && chown -R appuser:appuser /app
USER appuser

# Streamlit's default port
EXPOSE 8501

# Swap in your entrypoint, e.g.:
# CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0", "--server.port=8501"]
CMD ["python"]