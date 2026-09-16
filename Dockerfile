FROM condaforge/miniforge3:latest

ARG PYTHON_VERSION=3.12
ARG ENV_NAME=app

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# System libraries needed by OpenCV (pulled in by presidio-image-redactor)
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Create the conda environment with Python and Tesseract OCR from conda-forge
RUN mamba create -y -n ${ENV_NAME} python=${PYTHON_VERSION} tesseract \
    && conda clean -afy

# Put the environment first on PATH so python/pip/tesseract resolve to it.
# TESSDATA_PREFIX is normally set by conda's activation script, which doesn't
# run here, so set it explicitly.
ENV PATH=/opt/conda/envs/${ENV_NAME}/bin:$PATH \
    CONDA_DEFAULT_ENV=${ENV_NAME} \
    TESSDATA_PREFIX=/opt/conda/envs/${ENV_NAME}/share/tessdata

WORKDIR /app

# Install dependencies first so this layer is cached across code changes
COPY requirements.txt .
RUN pip install -r requirements.txt

# Fail the build early if Tesseract or the image redactor can't load
RUN tesseract --list-langs \
    && python -c "import presidio_image_redactor"

# Copy the rest of the project
COPY . .

# Streamlit's default port
EXPOSE 8501

# Swap in your entrypoint, e.g.:
# CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0", "--server.port=8501"]
CMD ["python"]