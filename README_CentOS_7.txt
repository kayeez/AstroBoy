搭建环境准备：
1.磁盘空间
   1.系统磁盘保证有至少有100G空余
   2.系统语言环境为en_US.UTF-8
   
2.依赖镜像文件：
    服务器系统版本镜像文件(该镜像文件包含rpm)：如CentOS-7-x86_64-DVD-1511.iso   约4G
	注：镜像版本必须要和安装系统时所用版本一模一样
	
3.大数据平台安装包(centos 7、redHat7)：
	ambari-2.4.2.0-centos7.tar.gz     约1.3G  下载地址：http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.4.2.0/ambari-2.4.2.0-centos7.tar.gz
	HDP-2.5.3.0-centos7-rpm.tar.gz    约5.3G  下载地址：http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/2.5.3.0/HDP-2.5.3.0-centos7-rpm.tar.gz
	HDP-UTILS-1.1.0.21-centos7.tar.gz 约0.87G 下载地址：http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.21/repos/centos7/HDP-UTILS-1.1.0.21-centos7.tar.gz
	
4.JDK准备：
    准备一个jdk rpm包放置到服务器上
	如：jdk-7u80-linux-x64.rpm
	
5.将以上 5 个文件拷贝到任意一台服务器上