FROM debian:latest

# Copy the userinstall.sh script into the container
COPY Userinstall.sh /tmp/Userinstall.sh

# Make the script executable
RUN chmod +x /tmp/Userinstall.sh
EXPOSE 8080:8080

# Run the script
CMD ["/bin/bash", "-c", "/tmp/Userinstall.sh && /bin/bash"]

# Open a tty for interactive use
# This is more for development, you might remove this in production
# You can run this file with ```docker run -itp 8080:8080 revermb/debiantest:latest