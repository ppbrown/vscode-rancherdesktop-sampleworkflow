FROM python:3.13-slim

# Run as a non-root user, as most enterprise clusters require.
RUN useradd --uid 10001 --create-home app
WORKDIR /app
COPY --chown=app:app app/ /app/
USER 10001

EXPOSE 8080
CMD ["python", "main.py"]
