#!/bin/bash

if [ $# -ne 3 ]; then
   echo "Usage:"
   echo -e "\t ${0} dbuser dbpass dbname"
   exit 1
fi
DBUSER="$1"
DBPASSWD="$2"
DBNAME="$3"
NOWDBNAME="thundersoft"
CMD_MYSQL="/usr/local/mysql/bin/mysql"
DATA_TIME=`date +%y%m%d`

#新建目录并修改权限
#mkdir -p ${SAVEDIR}
#chown mysql:mysql ${SAVEDIR}

#在数据统计数据库建一个数据统计表 ${DBNAME}_${DATA_TIME}_bugs
project="create table ${DBNAME}_${DATA_TIME}_bugs (
  id mediumint(9) NOT NULL AUTO_INCREMENT,
  product varchar(64) NOT NULL,
  component varchar(64) NOT NULL,
  bug_severity varchar(64) NOT NULL,
  creation_ts datetime NOT NULL,
  bug_reporter varchar(64) NOT NULL,
  bug_id mediumint(9) NOT NULL,
  state_from varchar(64) DEFAULT NULL,
  state_to varchar(64) DEFAULT NULL,
  owner varchar(64) DEFAULT NULL,
  bug_when datetime DEFAULT NULL,
  spend_time mediumint DEFAULT NULL,
  type varchar(2) DEFAULT NULL,
  PRIMARY KEY (id)
);"
${CMD_MYSQL} -u ${DBUSER} -p${DBPASSWD} ${NOWDBNAME} -e "${project}"

#从目标数据库导出数据到数据统计数据库的${DBNAME}_${DATA_TIME}_bugs表中
project="insert into thundersoft.${DBNAME}_${DATA_TIME}_bugs(product,component,bug_severity,creation_ts,bug_reporter,bug_id,state_from,state_to,owner,bug_when) 
select z.product,z.component,z.bug_severity,z.creation_time,z.bugreporter,z.bug_id,z.state_from,z.state_to,d.login_name as owner,z.bug_when 
from profiles d right join 
(select b.product,b.component,a.bug_id,b.bug_severity,b.creation_time,b.bugreporter,a.removed as state_from,a.added as state_to,a.who,a.bug_when from (select a.bug_id,a.added,a.removed,a.who,a.bug_when from bugs_activity a where fieldid =9  order by a.bug_id) as a right join (select h.product,g.name as component,h.bug_id,h.bug_severity,h.creation_time,h.bugreporter from components g right join (select e.*,f.name as product from products f right join(select c.*,d.login_name as bugreporter  from profiles d            right join (select a.product_id,a.bug_severity,a.component_id,a.bug_id,a.reporter,bug_status,b.who,a.creation_ts as creation_time from bugs a                       left join bugs_activity b on a.bug_id = b.bug_id                        group by a.bug_id) as c on d.userid=c.reporter            group by c.bug_id) as e on f.id = e.product_id group by e.bug_id) as h on g.id=h.component_id) b on a.bug_id=b.bug_id)
 z on d.userid=z.who;"
${CMD_MYSQL} -u ${DBUSER} -p${DBPASSWD} ${DBNAME} -e "${project}"

#通过比较BUG ID前后不同计算BUG第一次出现时状态变换花费的时间

project="UPDATE ${DBNAME}_${DATA_TIME}_bugs,(select b.* from ${DBNAME}_${DATA_TIME}_bugs a right join (select a.id,b.bug_id,b.creation_ts,TIMESTAMPDIFF(HOUR,a.creation_ts,a.bug_when) as spend_time 
from ${DBNAME}_${DATA_TIME}_bugs a 
left join ${DBNAME}_${DATA_TIME}_bugs b on a.id = b.id+1 
where b.bug_id != a.bug_id) b on a.id =b.id) as y set ${DBNAME}_${DATA_TIME}_bugs.spend_time=y.spend_time where ${DBNAME}_${DATA_TIME}_bugs.id=y.id;"
${CMD_MYSQL} -u ${DBUSER} -p${DBPASSWD} ${NOWDBNAME} -e "${project}"

#当中BUG有多个状态变化时 计算BUG第二次出现到结束状态变换花费的时间

project="UPDATE ${DBNAME}_${DATA_TIME}_bugs,(select b.* from ${DBNAME}_${DATA_TIME}_bugs a right join (select a.id,a.bug_id,b.creation_ts,TIMESTAMPDIFF(HOUR,b.bug_when,a.bug_when) as spend_time 
from ${DBNAME}_${DATA_TIME}_bugs a 
left join ${DBNAME}_${DATA_TIME}_bugs b on a.id = b.id+1 
where a.bug_id = b.bug_id) b on a.id =b.id) as y set ${DBNAME}_${DATA_TIME}_bugs.spend_time=y.spend_time where ${DBNAME}_${DATA_TIME}_bugs.id=y.id;"
${CMD_MYSQL} -u ${DBUSER} -p${DBPASSWD} ${NOWDBNAME} -e "${project}"

#计算第一个BUG（第一个BUG通过上边计算会被漏掉）的状态变换花费的时间

project="update ${DBNAME}_${DATA_TIME}_bugs set ${DBNAME}_${DATA_TIME}_bugs.spend_time=TIMESTAMPDIFF(HOUR,${DBNAME}_${DATA_TIME}_bugs.creation_ts,${DBNAME}_${DATA_TIME}_bugs.bug_when) where ${DBNAME}_${DATA_TIME}_bugs.id=1;"
${CMD_MYSQL} -u ${DBUSER} -p${DBPASSWD} ${NOWDBNAME} -e "${project}"

#将表${DBNAME}_${DATA_TIME}_bugs的type列全部设为D（D即为DEVELOP P为PREPARE）

project="update ${DBNAME}_${DATA_TIME}_bugs set ${DBNAME}_${DATA_TIME}_bugs.type= 'D';"
${CMD_MYSQL} -u ${DBUSER} -p${DBPASSWD} ${NOWDBNAME} -e "${project}"

#将表${DBNAME}_${DATA_TIME}_bugs的type列状态变化由UNCONFIRMED->ASSIGNED CONFIRMED->ASSIGNED  设为P（D即为DEVELOP P为PREPARE）

project="update ${DBNAME}_${DATA_TIME}_bugs set ${DBNAME}_${DATA_TIME}_bugs.type= 'P' where (${DBNAME}_${DATA_TIME}_bugs.state_from='UNCONFIRMED' and ${DBNAME}_${DATA_TIME}_bugs.state_to='ASSIGNED') or (${DBNAME}_${DATA_TIME}_bugs.state_from='CONFIRMED' and ${DBNAME}_${DATA_TIME}_bugs.state_to='ASSIGNED');"
${CMD_MYSQL} -u ${DBUSER} -p${DBPASSWD} ${NOWDBNAME} -e "${project}"

