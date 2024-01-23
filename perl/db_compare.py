#!/usr/bin/env python3

import sys
import sqlite3


def compare_with_database( line, cursor, system, runno, variation ):
	# Split the line into fields
	fields = line.split( '|' )

	# Extract values from the line
	name, mother, dummy1, pos, rot, color, shape, shape_params, material, *other = [
		f.strip() for f in fields ]

	# Query the database using the extracted values
	query = f"SELECT * FROM geometry WHERE name=? AND mother=? AND pos=? AND rot=? AND col=? AND type=? AND dimensions=? AND material=? and system=? and run=? and variation=?"
	cursor.execute( query, ( name, mother, pos, rot, color, shape, shape_params, material, system, runno, variation ) )

	# Fetch the result
	result = cursor.fetchone()

	# if the fetch is 1, then the line is in the database. Print the name of the volume
	if result is not None:
		print( f"Comparison with {result[4]} succeeded." )

	# Check if the result is not None, indicating a match
	return result is not None


def main():
	# file_path is first argument to this file
	file_path = sys.argv[1]
	database_path = sys.argv[2]
	system = sys.argv[3]
	runno = sys.argv[4]
	variation = sys.argv[5]

	table_name = 'geometry'

	try:
		# Connect to the database
		connection = sqlite3.connect( database_path )
		cursor = connection.cursor()

		with open( file_path, 'r' ) as file:
			lines = file.readlines()

		# Compare each line with the database
		for i, line in enumerate( lines ):
			if not compare_with_database( line, cursor, system, runno, variation ):
				print( f"Line {i + 1} does not match the database." )
				print ( line )
				break
		else:
			print( "All lines match the database." )

	except FileNotFoundError:
		print( f"File '{file_path}' not found." )
	except sqlite3.Error as e:
		print( f"SQLite error: {e}" )
	finally:
		# Close the database connection
		if connection:
			connection.close()


if __name__ == "__main__":
	main()
