# Use an appropriate Python base image
FROM python:3.9-slim

# Install required packages
RUN apt-get update && apt-get install -y openssh-client

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install the required Python packages
RUN pip install -r ethos-pods-api/requirements.txt

# Copy the entrypoint script into the container
COPY ethos-pods-api/entrypoint.sh /entrypoint.sh

# Ensure the entrypoint script is executable
RUN chmod +x /entrypoint.sh

# Expose the port the server will run on
EXPOSE 8000

# Run the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]