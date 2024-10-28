'''
#Reads an obj file and returns a tsi file to be used as input in TS2CG
#Author: Rubi Zarmiento Garcia
#Date: 17/08/2023
#Version: 1.0.0.0

Arguments:
    -i: input file
    -o: output file
    -material: Add material as a domain index, by default False
    -scale: scale factor to scale the vertices, by default 1.0
    -decimals: Number of decimals to round the vertices and box size, by default 9
    -d : Displace vertices to the origin in order to have only positive values
    -box: box size, by default the maximum distance between vertices
Usage:
    obj_to_tsi.py -i input.obj -o output.tsi    
'''

#Import libraries
import sys
import getopt
import os
import numpy as np
import math
import argparse
import pandas as pd

#Parse arguments
def parse_arguments():
    parser = argparse.ArgumentParser(description='Reads an obj file and returns a tsi file to be used as input in TS2CG')
    parser.add_argument('-i', type=str, help='input file')
    parser.add_argument('-o', type=str, help='output file')
    parser.add_argument('-material', action='store_true', help='Add material as a domain index, by default False')
    parser.add_argument('-scale', type=float, help='scale factor to scale the vertices, by default 1.0', default=1.0)
    parser.add_argument('-decimals', type=int, help='Number of decimals to round the vertices and box size, by default 9', default=9)
    parser.add_argument('-d', action='store_true', help='Displace vertices to the origin in order to have only positive values')
    parser.add_argument('-box', type=float, nargs=3, help='box size, by default the maximum distance between vertices')
    args = parser.parse_args()
    return args

#Check arguments
def check_arguments(args):
    if not os.path.isfile(args.i):
        print("The file does not exist")
        exit()
    return args

#Read obj file and return vertices and triangles
def read_obj_file(args):
    vertices = []
    triangles = []
    material_count = 0
    material_dict = {}
    with open(args.i, 'r') as f:
        for line in f:
            parts = line.strip().split()
            if not parts:
                continue

            if parts[0] == 'v':
                vertices.append(tuple(map(float, parts[1:4])))

            if parts[0] == 'f':
                triangle = [int(p.split('/')[0]) for p in parts[1:4]]
                if args.material:
                    #Add the material index to the triangle
                    triangle = triangle + [material_count]
                triangles.append(triangle)

            if args.material:
                if parts[0] == 'g':
                    material_name = parts[1]
                    material_dict[material_name] = material_count
                    print("The material " + material_name + " has the index " + str(material_count))
                    material_count += 1


        

    box_size = np.max(vertices, axis=0) - np.min(vertices, axis=0)
    
 
    #Scale vertices by scale factor
    vertices = np.array(vertices) * args.scale
    box_size = box_size * args.scale

    #Checl if any vertex is negative
    if np.any(vertices < 0):
        print("The vertices are not positive, if you want to displace them to the origin, use the option -d. ")
    #    exit()
    #Displace vertices to the origin in order to have only positive values
    if args.d:
        vertices = vertices - np.min(vertices, axis=0)
        box_size = box_size - np.min(box_size, axis=0)

    #Round vertices and box size 
    vertices = np.around(vertices, decimals=args.decimals)
    if args.box:
        box_size = np.array(args.box)
    else:
        box_size = np.around(box_size, decimals=args.decimals)
        box_size = box_size * 1.1
    #Rest one to the triangles to start from 0
    triangles = np.array(triangles) - 1

    if args.material:
        # Get unique keys (fourth column)
        keys = np.unique(triangles[:, 3])

        # Split array into a dictionary
        split_dict = {key: triangles[triangles[:, 3] == key, :-1] for key in keys}
        #Unique vertices
        new_vertices = []
        split_dict = {key: np.unique(split_dict[key]) for key in split_dict}
        for key in split_dict:
            unique_vertices = split_dict[key]
            for v in unique_vertices:
                new_vertices.append(np.append(vertices[v], key))
        vertices = np.array(new_vertices)
    else:
        #Add a column with zeros
        vertices = np.append(vertices, np.zeros((len(vertices), 1)), axis=1)
    #Increase box_size by 10% to avoid with TS2CG
    return vertices, triangles, box_size, material_dict


#Write tsi file format:
#version 1.1
#box ${x} ${y} ${z} 
#vertex n_vertex
#vertexid x y x
#...
#triangle n_triangle
#triangleid v1 v2 v3 v4
#...

def write_tsi_file(args, vertices, triangles, box_size, material_dict):
    #Open output file
    with open(args.o, 'w') as f:
        #Write version
        f.write("version 1.1\n")
        #Write box size is equal to the maximum distance between vertices
        f.write("box     {:.10f}     {:.10f}     {:.10f}\n".format(box_size[0], box_size[1], box_size[2]))
        #Write vertices
        f.write("vertex                 {}\n".format(len(vertices)))
        #Make sure the vertices have 9 decimals
        for i, v in enumerate(vertices):
            f.write("    {}      {:.10f}      {:.10f}      {:.10f}      {:.0f}\n".format(i, v[0], v[1], v[2], v[3]))        #Write triangles
        f.write("triangle {}\n".format(len(triangles)))
        for i, t in enumerate(triangles):
            f.write("     {}      {}      {}      {}\n".format(i, t[0], t[1], t[2]))
        #Print message
        full_path = os.path.abspath(args.o)
        print("\nThe tsi file " + full_path + " was created")
        #Print number of vertices and triangles
        print("\nThe system has {} vertices and {} triangles".format(len(vertices), len(triangles)))
        #Print box size
        print("\nThe box size is {} x {} x {} nm\n".format(box_size[0], box_size[1], box_size[2]))
        #If -material is used, print the material dictionary
        if args.material:
            print("The domains dictionary is: ")
            print(material_dict)
            #Write file with material dictionary with the same name as the tsi file
            material_file = args.o.split(".")[0] + "_domains.txt"
            with open(material_file, 'w') as f:
                f.write("The domains' dictionary is: \n")
                f.write(str(material_dict))
            print("The domains dictionary was saved in " + material_file + "\n")

#Main function
def main():
    #Parse arguments
    args = parse_arguments()
    #Check arguments
    args = check_arguments(args)
    #Read obj file
    vertices, triangles, box_size, material_dict = read_obj_file(args)
    #Write tsi file
    write_tsi_file(args, vertices, triangles, box_size, material_dict)

#Run main function
if __name__ == "__main__":
    main()
    
