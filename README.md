# Secure Administration Environment Lab
This repo contains a simplified environment based on our training environment for Secure Administration Environment (or SAE, a Microsoft security concept).
It allows an automated deployment of basic networking with one Windows machine, that is as last step modified by a Powershell script. 
The script injected into the machine using Machine Extensions (an Azure mechanism).

To run:
git clone the repo
az login (azure CLI)

in main dir:
terraform init
terraform plan
terraform apply

The final script will take an odd amount of time. That is because even if terraform gets notified that the Windows machine is ready, in reality it it not.
That makes the used Extension wait. The execution time of the script is milliseconds.
That you can check using RDP to the machine (it will have the RDP port open and the credentials are in the file - CHANGE THEM BEFORE USING THE SCRIPT). 


