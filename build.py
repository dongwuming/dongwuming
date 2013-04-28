#!/usr/bin/env python
# Author caotao@thunderst.com
# Version 1.1
import os
import sys, stat
import string, re
import commands
import subprocess 
import ConfigParser
from time import strftime

gitLogFileName="gitlog-%s" % ( strftime("%Y%m%d%H%M%S") )
islogempty = False

gl_product_name = ""

__e1 = re.compile( r"error:" )
_realdir = os.path.dirname(os.path.realpath(__file__))
_realbasename = os.path.basename(os.path.realpath(__file__))
#print "_realdir = %s" % _realdir
#print "_realbasename = %s" % _realbasename

class Project(object):
	def __init__(self, name):
		self.name = name
		p = self._getvar()
		self.workdir = p['workdir']
		self.logdir = p['logdir']
		self.maillist = p['maillist']
		self.codeurl = p['codeurl']
		self.buildscript = p['buildscript']
		self.tag = p['tag']
		self.product_name = p['product_name']
		self.build_opt = p['build_opt']
		self.release_dir = p['release_dir']
		global gl_product_name
		gl_product_name = self.product_name
	def _getvar(self):
		cd = Config().cset
		c = cd[self.name]
		return c


class Config(object):
#	def __init__(self, config=os.path.expanduser("~/build.ini")):
	def __init__(self, config=os.path.join(_realdir, _realbasename.replace(".py", ".ini"))):
		self.conf = config
#		print "ini file = %s" % config
		self.cset = self.check()
	def config(self):
		c = {}
		cf = ConfigParser.ConfigParser()
		cf.read(self.conf)
		for x in cf.sections(): c[x] = dict(cf.items(x))
		return c
	def check(self):
		a = self.config()
		for K, V in a.items():
			for k, v in V.items():
				if v is '':
					print """
	+++++++++++++++++++++++++++++++++++++++++++
	Project %s's %s is 
	invalid, please modify build.ini
	+++++++++++++++++++++++++++++++++++++++++++
	""" % (K, k)
					exit(2)
		return a

class Mail(object):
	def __init__(self, project):
		self.pro = project
	def maile(self, msg):
		maillst = self.pro.maillist
		sub = "build errors"
		head = "all"
		err = """
		==================== errors ====================
		%s
		==================== errors ====================
		""" % msg
		self.sendm(maillist, head, sub, err)

	def mailc(self, subject, msg):
		to = "scm@thundersoft.com"
		sub = subject
		head = "scm"
		message = """
		-------------------- msg --------------------
		%s
		-------------------- msg --------------------
		""" % (msg)
		self.sendm(to, sub, head, message)

	def sendm(self, to, sub, head, msg):
		info = """
		To: %s
		Subject: %s

		\n
		Hi %-s,
		%s
		\n

		Best Regards,

		""" % (to, sub, head, msg)
		SENDMAIL = "/usr/sbin/sendmail" # sendmail location
		p = os.popen("%s -t" % SENDMAIL, "w")
		p.writelines(info)
		sts = p.close()
		if sts <> 0:
			print "Sendmail exit status", sts

class Code(object):
	__sync = False
	__branch = False
	__dotag = False
	__open = False
	__close = False
	__pushtag = False
	tag = ' '
	name = ''
	def __init__(self, project):
		self.project = project
		Code.tag = project.tag
		Code.name = project.name
	def sync(self):
		if not os.access(os.path.expanduser(os.path.join(self.project.workdir, gl_product_name)), os.F_OK):
			os.makedirs(os.path.expanduser(os.path.join(self.project.workdir, gl_product_name)))
		os.chdir(os.path.expanduser(os.path.join(self.project.workdir, gl_product_name)))
        #        cmd = "repo sync  && create-patches.sh %s %s && repo forall -c 'get_git_log.sh' > %s" % ( gl_product_name, self.project.workdir, gitLogFileName )
                cmd = "repo sync  && repo forall -c 'get_git_log.sh' > %s" % ( gitLogFileName )
		self.__do(cmd)
		Code.__sync = True
		data = open(gitLogFileName).read()
		if len(data) == 0:
			global islogempty
			islogempty = True



	def close(self):
		pass
	def open(self):
		pass
	def branch(self):
		if not Code.__sync:
			print >> sys.stderr, "error: have not synced cuccessfully"
			exit(2)
		os.chdir(os.path.expanduser(os.path.join(self.project.workdir, gl_product_name)))
		cmd = "repo start build"
		self.__do(cmd)
		Code.__branch = True
	def dotag(self):
		if not Code.__dotag:
			self.sync()
		if Code.tag == 'DATE':
			Code.tag = strftime("%Y%m%d%H%M%S")
		#cmd = "repo forall -c " + "git -a " + tag + " -m " + "\"" + tag + " for daily build" + "\""
		os.chdir(os.path.expanduser(os.path.join(self.project.workdir, gl_product_name)))
		cmd = "repo forall -c " + "git tag " + Code.tag + " -m " + "\"tag for daily build.\""
		self.__do(cmd)
		Code.__dotag = True
	def prebuild(self):
		close()
		branch()
	def pushtag(self):
		if not _pushtag:
			pass
	def __do(self, cmd):
		a = commands.getstatusoutput(cmd + " 2>&1")
		p = self.project
		f = open(os.path.expanduser(os.path.join(self.project.workdir, gl_product_name + '-' + Code.tag + '-update.txt')), 'a')
		if a[0] <> 0:
			#print a[1]
			print >> f, a[1]
			f.close()
			exit(2)
		print >>f, '================= ' + strftime("%Y%m%d%H%M%S") + " =================\n\n"
		f.close()


class Build(object):
	def __init__(self, project): 
		self.pro = Project(project[0])
		self.mail = Mail(self.pro)
		self.code = Code(self.pro)

	def build(self):
		#env = dict(os.environ)
		p = self.pro
		w = os.path.expanduser(os.path.join(p.workdir, p.product_name))
		try:
			os.chdir(os.path.expanduser(w))
		except OSError, e:
			print e
		dts = strftime("%Y%m%d%H%M%S")
		if not os.access(os.path.expanduser(p.logdir), os.F_OK):
			os.makedirs(os.path.expanduser(p.logdir))
		self.outf = open(os.path.expanduser(os.path.join(p.logdir, p.name + "-" + p.tag + "-" + dts + ".txt")), 'w+')
		if not os.access(os.path.expanduser(os.path.join(w, p.buildscript)), os.F_OK):
			print "p.buildscript is invalid."
			sub = "buildscript is invalid."
			msg = "buildscript is invalid."
			self.mail.mailc(sub, msg)
			exit(2)
		if not os.access(os.path.expanduser(os.path.join(w, p.buildscript)), os.X_OK):
			os.chmod(os.path.expanduser(os.path.join(w, p.buildscript), stat.S_IXUSR))
		bs = os.path.abspath(p.buildscript)
		cmd = "%s %s %s %s %s" % (bs, Code.tag, p.product_name, p.build_opt, p.release_dir)
		self.process = subprocess.Popen(cmd, shell=True, cwd=w, close_fds=True, universal_newlines=True, stdout=self.outf, stderr=subprocess.STDOUT)
		try:
			retcode = self.process.wait()
			if retcode < 0:
				print >>sys.stderr, "Process was terminated by signal", -retcode
			else:
				print >>sys.stderr, "Process returned", retcode
		except OSError, e:
			print >>sys.stderr, "Execution failed:", e

	def errors(self):
		err = []
		for l in self.outf:
			m = __e1.search(l)
			if m:
				err.appand(l)
		return err

	def mail(self):
		self.mail.maile(self.errs())
		#TODO:
		print "build ok......."

def main():
	a = Build(sys.argv[1:])
	a.code.sync()
	if islogempty == True :
		pp = os.popen("echo 'There was nothing updated yesterday, so we will not do the DailyBuild, thanks!' |mutt -s '[Carrier-LA1.7-dev] DailyBuild %s' -- ncmc_kgm@thundersoft.com kaka-pm@thundersoft.com kaka-dm@thundersoft.com kaka_sh@thundersoft.com scm@thundersoft.com" % strftime("%Y-%m-%d"))
		pp.close
		exit(3)
	a.build()
	#a.errors()
	#a.mail()

if __name__ == "__main__":
	main()
