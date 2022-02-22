# aws-template
Scripts to create an EC2 instance and associated resources for a python project

* create_instance will:
  * Create a KeyPair and PEM file for accessing the instance
  * Create a Public IP linked to your default VPC
  * Create a security group which is open to all IPs for SSH, HTTP and HTTPs. Opening these ports to all IPs is not recommended
  * Create an instance and assign the IP address
  * Log into the instance, install poetry and pyenv
  * install a recent version of python using pyenv and set as the local version
* start_and_connect will:
  * Start the instance if not already started
  * log in using SSH
* stop_instance:
  * Stop the instance and leave all other resources in place
* clean_up:
  * Terminate the instance
  * Delete or release all instances associated with the instance
  
All resources are named with a project and machine tag for easy cleanup. Certain parameters 
can be set with variables at the beginning of each script: Project, Machine Name, 
Instance Type, Python Version, AMI Image. These variables should be set the same at the
top of each parameter.
