#!/usr/src/scons/russel/scons_d_tooling/bootstrap.py -f
import os.path

dmdroot = '/usr/src/d/dmd/src'
gdcroot = '/usr/src/d/gdcroot/bin'

compiler = ARGUMENTS.get('dc', 'dmd')
debug = ARGUMENTS.get('debug', 0)
release = ARGUMENTS.get('release', 0)
model = int(ARGUMENTS.get('model', 64))

incdirs = [ ]
libdirs = [ ]

dmd = dmdroot + os.sep + 'dmd'
gdmd = gdcroot + os.sep + 'gdmd'
gdc = gdcroot + os.sep + 'gdc'

if compiler == 'dmd':
	dc = dmd
elif compiler == 'gdmd':
	dc = gdmd
elif compiler == 'gdc':
	dc = gdc
else:
	print 'Unknown compiler: ' + compiler
	exit(1)

cflags = []
dflags_dmd = ['-I' + d for d in incdirs]
dflags_gdc = ['-I' + d for d in incdirs]
ldflags = ['-L' + d for d in libdirs]
ldflags += ['-L-gc-sections']

# Hack to work around bugs in Russell's tool
dflags_dmd += ['-L' + flags for flags in ldflags]

if model==64:
	dflags_dmd += ['-m64']
	dflags_gdc += ['-m64']
elif model==32:
	cflags += ['-m32']
	ldflags += ['-m32']
	dflags_dmd += ['-m32']
	dflags_gdc += ['-m32']
else:
	print 'Unsupported model: ', model
	Exit(1)

if debug:
	dflags_dmd += ['-g', '-debug']
	dflags_gdc += ['-g3', '-fdebug']
else:
	cflags += ['-O3']
	dflags_dmd += ['-O']
	dflags_gdc += ['-O3']

if release:
	dflags_dmd += ['-release']
	dflags_gdc += ['-frelease']
else:
	dflags_dmd += ['-unittest']
	dflags_gdc += ['-funittest']

if dc == dmd or dc == gdmd:
	dflags = dflags_dmd
	tools = ['default']
else:
	dflags = dflags_gdc
	tools = ['gcc', 'gnulink', 'gdc']

env = Environment(
	tools = tools,
	CFLAGS = cflags,
	DC = dc,
	DFLAGS = dflags,
	LINKFLAGS = ldflags
)

env.Program('symdep', Split("""
	symdep.d
"""))
