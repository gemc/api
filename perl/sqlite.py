#!/usr/bin/env python3

# Purposes:
# 1. function to create a sqlite database file with the geometry and materials tables
# 2. functions to fill the tables with the geometry and materials of a system

import argparse
import sys
import sqlite3
import os

NGIVEN: str = 'NOTGIVEN'
NGIVENS: [ str ] = [ 'NOTGIVEN' ]
MANDATORY = 'notSetYet'  # for mandatory fields. Used in function check_validity
OPTIONAL = 'na'  # for optionals fields
DEFAULTMOTHER = 'root'
DEFAULTCOLOR = '778899'


# GVolume class definition
# Matches the perl definitions of geometry.pm
class GVolume:

	def __init__( self ):
		# mandatory fields. Checked at publish time
		self.name = NGIVEN
		self.mother = DEFAULTMOTHER
		self.description = OPTIONAL

		self.pos = '0*mm, 0*mm, 0*mm'
		self.rot = [ '0*deg, 0*deg, 0*deg' ]
		self.col = DEFAULTCOLOR

		self.type = MANDATORY
		self.dimensions = MANDATORY

		self.material = MANDATORY
		self.magfield = OPTIONAL

		self.ncopy = 1
		self.pMany = 1
		self.exist = 1
		self.visible = 1  # 0 is invisible, 1 is visible
		self.style = 1  # 0 is wireframe, 1 is solid

		self.sensitivity = OPTIONAL
		self.hitType = OPTIONAL
		self.identity = OPTIONAL

class GMaterial:

	def __init__( self ):
		# mandatory fields. Checked at publish time
		self.name = NGIVEN
		self.description = MANDATORY
		self.density = MANDATORY
		self.ncomponents = MANDATORY
		self.components = MANDATORY
		self.photonEnergy = MANDATORY
		self.indexOfRefraction = MANDATORY
		self.absorptionLength = MANDATORY
		self.reflectivity = MANDATORY
		self.efficiency = MANDATORY
		self.fastcomponent = MANDATORY
		self.slowcomponent = MANDATORY
		self.scintillationyield = MANDATORY
		self.resolutionscale = MANDATORY
		self.fasttimeconstant = MANDATORY
		self.slowtimeconstant = MANDATORY
		self.yieldratio = MANDATORY
		self.rayleigh = MANDATORY
		self.birkConstant = MANDATORY




def main():
	# Provides the -h, --help message
	desc_str = "   SCI-G sql interface\n"
	sqlitedb: sqlite3.Connection = None

	variation_filter = ''
	system_filter = ''
	runno_filter = ''

	what = "*"

	parser = argparse.ArgumentParser( description=desc_str )

	# file writers
	parser.add_argument( '-l', metavar='<sqlite database name>', action='store', type=str,
	                     help='select the sqlite database filename', default=NGIVEN )

	parser.add_argument( '-n', metavar='<sqlite database name>', action='store', type=str,
	                     help='creates new sqlite database filename', default=NGIVEN )

	parser.add_argument( '-sv', action='store_true', help='show volumes from database' )
	parser.add_argument( '-sm', action='store_true', help='show materials from database' )

	parser.add_argument( '-vf', action='store', type=str,
	                     help='selects a variation filter for the volumes' )
	parser.add_argument( '-sf', action='store', type=str,
	                     help='selects a system filter for the volumes' )
	parser.add_argument( '-rf', action='store', type=str,
	                     help='selects a run number filter for the volumes' )
	parser.add_argument( '-what', action='store', type=str, help='show only the selected fields' )

	args = parser.parse_args()

	if args.n != NGIVEN:
		sqlitedb_file = args.n
		try:
			os.remove( sqlitedb_file )
			print( "  ❖ Removed existing database file: {}".format( sqlitedb_file ) )
		except OSError:
			pass

		sqlitedb = sqlite3.connect( sqlitedb_file )
		create_sqlite_database( sqlitedb )

		add_geometry_fields_to_sqlite_if_needed(  GVolume(), sqlitedb )
		add_materials_fields_to_sqlite_if_needed( GMaterial(), sqlitedb )


	if args.l != NGIVEN:
		sqlitedb = sqlite3.connect( args.l )

	if args.vf:
		variation_filter = f" WHERE variation = '{args.vf}'"

	if args.sf:
		if args.vf:
			system_filter = f" and system = '{args.sf}'"
		else:
			system_filter = f" WHERE system = '{args.sf}'"

	if args.rf:
		if args.vf or args.sf:
			runno_filter = f" and run = {args.rf}"
		else:
			runno_filter = f' WHERE run = {args.rf}'

	all_filters = variation_filter + system_filter + runno_filter

	if args.what:
		what = args.what

	if args.sv:
		show_volumes_from_database( sqlitedb, what, all_filters )

	if args.sm:
		show_materials_from_database( sqlitedb, what, all_filters )

	# if no argument is given print help
	if len( sys.argv ) == 1:
		parser.print_help( sys.stderr )
		print()
		sys.exit( 1 )


def show_volumes_from_database( sqlitedb, what, all_filters ):
	if sqlitedb is not None:
		sql = sqlitedb.cursor()
		query = "SELECT {} FROM geometry {};".format( what, all_filters )
		print( query )
		sql.execute( query )
		for row in sql.fetchall():
			print( row )


def show_materials_from_database( sqlitedb, what, all_filters ):
	if sqlitedb is not None:
		sql = sqlitedb.cursor()
		query = "SELECT {} FROM materials {};".format( what, all_filters )
		print( query )
		sql.execute( query )
		for row in sql.fetchall():
			print( row )


# create the database file (overwrite if it exists)
# create the tables geometry, materials, mirrors, parameters
def create_sqlite_database( sqlitedb ):
	sql = sqlitedb.cursor()

	# Create geometry table with one column
	sql.execute( '''CREATE TABLE geometry (id integer primary key)''' )

	# Create materials table with one column
	sql.execute( '''CREATE TABLE materials (id integer primary key)''' )

	# Save (commit) the changes
	sqlitedb.commit()


def add_geometry_fields_to_sqlite_if_needed( gvolume, sqlitedb ):
	# check if the geometry table has the geometry columns
	sql = sqlitedb.cursor()
	sql.execute( "SELECT name FROM PRAGMA_TABLE_INFO('geometry');" )
	fields = sql.fetchall()

	# if there is only one column, add the columns
	if len( fields ) == 1:
		add_column( sqlitedb, "geometry", "system", "TEXT" )
		add_column( sqlitedb, "geometry", "variation", "TEXT" )
		add_column( sqlitedb, "geometry", "run", "INTEGER" )
		# add columns from gvolume class
		for field in gvolume.__dict__:
			sql_type = sqltype_of_variable( gvolume.__dict__[ field ] )
			add_column( sqlitedb, "geometry", field, sql_type )
	sqlitedb.commit()


def add_materials_fields_to_sqlite_if_needed( gmaterial, sqlitedb ):
	# check if the geometry table has the geometry columns
	sql = sqlitedb.cursor()
	sql.execute( "SELECT name FROM PRAGMA_TABLE_INFO('materials');" )
	fields = sql.fetchall()

	# if there is only one column, add the columns
	if len( fields ) == 1:
		add_column( sqlitedb, "materials", "system", "TEXT" )
		add_column( sqlitedb, "materials", "variation", "TEXT" )
		add_column( sqlitedb, "materials", "run", "INTEGER" )
		# add columns from gmaterial class
		for field in gmaterial.__dict__:
			if field != 'compType' and field != 'totComposition':
				sql_type = sqltype_of_variable( gmaterial.__dict__[ field ] )
				add_column( sqlitedb, "materials", field, sql_type )
	sqlitedb.commit()






def sqltype_of_variable( variable ) -> str:
	if type( variable ) is int:
		return 'INT'
	elif type( variable ) is str:
		return 'TEXT'


def add_column( db, tablename, column_name, var_type ):
	sql = db.cursor()
	strn = "ALTER TABLE {0} ADD COLUMN {1} {2}".format( tablename, column_name, var_type )
	# print(strn)
	sql.execute( strn )
	db.commit()


if __name__ == "__main__":
	main()
