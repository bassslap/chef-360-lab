#!/bin/bash
echo "Temporarily changing template_id from 9000 to 999..."
sed -i.bak 's/template_id.*=.*9000/template_id         = 999/' terraform.tfvars
echo "Updated terraform.tfvars - you can change it back after creating template 9000"
