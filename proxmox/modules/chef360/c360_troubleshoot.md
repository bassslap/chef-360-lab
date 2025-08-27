ubuntu@chef360-linux-01:~$ ls
chef-360  chef-360-error.log  chef-360-install.log  chef-360-rc.tgz  license.yaml
ubuntu@chef360-linux-01:~$ 
ubuntu@chef360-linux-01:~$ 
ubuntu@chef360-linux-01:~$ 
ubuntu@chef360-linux-01:~$ ./chef-360 shell
ERROR: shell command must be run as root
ubuntu@chef360-linux-01:~$ sudo ./chef-360 shell

    __4___
 _  \ \ \ \   Welcome to chef-360 debug shell.
<'\ /_/_/_/   This terminal is now configured to access your cluster.
 ((____!___/) Type 'exit' (or Ctrl+D) to exit.
  \0\0\0\0\/
 ~~~~~~~~~~~
root@chef360-linux-01:/home/ubuntu# export KUBECONFIG="/var/lib/embedded-cluster/k0s/pki/admin.conf"
root@chef360-linux-01:/home/ubuntu# export PATH="$PATH:/var/lib/embedded-cluster/bin"
root@chef360-linux-01:/home/ubuntu# source <(k0s completion bash)
root@chef360-linux-01:/home/ubuntu# source <(cat /var/lib/embedded-cluster/bin/kubectl_completion_bash.sh)
root@chef360-linux-01:/home/ubuntu# source /etc/bash_completion
root@chef360-linux-01:/home/ubuntu# 
root@chef360-linux-01:/home/ubuntu# 
root@chef360-linux-01:/home/ubuntu# kubectl get pods
No resources found in default namespace.
root@chef360-linux-01:/home/ubuntu# kubectl get pods -n chef-360
NAME                                                              READY   STATUS      RESTARTS      AGE
chef-360-chef-courier-experience-api-7db4799df7-dgvl8             1/1     Running     0             58m
chef-360-chef-node-experience-api-5fdd68d9d9-snvqc                1/1     Running     0             58m
chef-360-chef-platform-authz-service-67bd46484d-wvcnx             1/1     Running     0             58m
chef-360-chef-platform-bundled-tools-7f575859c-z96gb              1/1     Running     0             58m
chef-360-chef-platform-chronos-service-868dd96695-x7s7g           1/1     Running     0             58m
chef-360-chef-platform-license-consumption-auditor-666cd68v86rb   1/1     Running     0             58m
chef-360-chef-platform-license-consumption-collector-64cf564ht5   1/1     Running     0             58m
chef-360-chef-platform-license-management-77d8bc6cdc-bvm5d        1/1     Running     0             58m
chef-360-chef-platform-license-proxy-66cb48798f-qfz9n             1/1     Running     6 (51m ago)   58m
chef-360-chef-platform-license-usage-bdf9d74cb-69tgm              1/1     Running     0             58m
chef-360-chef-platform-node-accounts-service-5b475b8845-l6h9p     1/1     Running     0             58m
chef-360-chef-platform-notification-service-654bb55448-ndsqr      1/1     Running     0             58m
chef-360-chef-platform-secret-service-cc4d9747d-vs7cq             1/1     Running     0             58m
chef-360-chef-platform-system-service-744cb64db-m995n             1/1     Running     0             58m
chef-360-chef-platform-user-accounts-service-84fb9d5f7b-qt629     1/1     Running     0             58m
chef-360-common-service-job-post-deployment-47kwl                 0/1     Completed   0             52m
chef-360-delivery-74fc797686-kt4wd                                1/1     Running     0             58m
chef-360-embedded-chef-web-docs-868d99bf5d-mp2b4                  1/1     Running     0             58m
chef-360-enrollment-worker-59c94cc784-mmjf9                       1/1     Running     0             58m
chef-360-internal-api-gateway-58b96bcfbd-znc6x                    1/1     Running     0             58m
chef-360-jm-authz-service-1-fhwdz                                 0/1     Completed   0             58m
chef-360-jm-courier-orchestrator-sentry-1-m7zvc                   0/1     Completed   0             58m
chef-360-jm-courier-scheduler-1-kpvhb                             0/1     Completed   0             58m
chef-360-jm-courier-state-1-vrk7n                                 0/1     Completed   0             58m
chef-360-jm-license-consumption-auditor-service-1-jf65f           0/1     Completed   0             58m
chef-360-jm-license-consumption-collector-service-1-6sbfs         0/1     Completed   0             58m
chef-360-jm-license-management-1-z6fgj                            0/1     Completed   0             58m
chef-360-jm-node-account-service-1-fgnpj                          0/1     Completed   0             58m
chef-360-jm-node-enrollment-1-r7cws                               0/1     Completed   0             58m
chef-360-jm-node-management-server-1-vwdg9                        0/1     Completed   0             58m
chef-360-jm-notification-service-1-c5kbf                          0/1     Completed   0             58m
chef-360-jm-secret-service-1-qcl45                                0/1     Completed   0             58m
chef-360-jm-system-service-1-cfkjk                                0/1     Completed   0             58m
chef-360-jm-user-account-service-1-fmgbm                          0/1     Completed   0             58m
chef-360-keydb-master-0                                           1/1     Running     0             58m
chef-360-mailpit-5958ccd768-r8q4w                                 1/1     Running     0             58m
chef-360-minio-59645f5cb7-xwmj4                                   1/1     Running     0             58m
chef-360-nginx-reverse-proxy-86796949d5-t7rf7                     1/1     Running     0             52m
chef-360-node-enrollment-api-575f554579-9v4cr                     1/1     Running     0             58m
chef-360-node-management-server-b6d59d9d5-vnvlg                   1/1     Running     0             58m
chef-360-orchestrator-sentry-b55b65848-qqq7c                      1/1     Running     0             58m
chef-360-platform-ui-64dbd7d8df-kw7xn                             1/1     Running     0             58m
chef-360-postgres-post-upgrade-nwzsm                              0/1     Completed   0             53m
chef-360-postgresql-ha-pgpool-ff798d4b6-bvzdt                     1/1     Running     0             58m
chef-360-postgresql-ha-postgresql-0                               1/1     Running     0             58m
chef-360-public-api-gateway-79f84cfb65-vw4b8                      1/1     Running     0             58m
chef-360-rabbitmq-0                                               1/1     Running     0             58m
chef-360-rabbitmq-v97r9                                           0/1     Completed   0             58m
chef-360-scheduler-75fcb86d77-ldn6v                               1/1     Running     0             58m
chef-360-scheduler-worker-df9f7fc98-k54j8                         1/1     Running     0             58m
chef-360-state-65b9db96fd-2x7mp                                   1/1     Running     0             58m
replicated-599fb9546d-gcksv                                       1/1     Running     0             58m
secret-key-generator-job-vgdj2                                    0/1     Completed   0             58m
root@chef360-linux-01:/home/ubuntu# kubectl get pods -n chef-360 -w
NAME                                                              READY   STATUS      RESTARTS      AGE
chef-360-chef-courier-experience-api-7db4799df7-dgvl8             1/1     Running     0             58m
chef-360-chef-node-experience-api-5fdd68d9d9-snvqc                1/1     Running     0             58m
chef-360-chef-platform-authz-service-67bd46484d-wvcnx             1/1     Running     0             58m
