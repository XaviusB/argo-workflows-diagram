#!/usr/bin/env python3

import argparse, os, yaml, pygraphviz
from graphviz2drawio import graphviz2drawio

def flatten_yaml_array(data):
    result = []

    for item in data:
        if isinstance(item, list):
            result.extend(flatten_yaml_array(item))
        else:
            result.append(item)

    return result

def dag_to_graphviz(tasks, graph):

    for task in tasks:
        if 'dependencies' in task:
            for dependency in task['dependencies']:
                graph.add_edge(dependency, task['name'])

    # Change the style of the nodes that do not have dependencies
    for task in tasks:
        if 'dependencies' not in task:
            node = graph.get_node(task['name'])
            node.attr['style'] = 'filled'
            node.attr['fillcolor'] = 'lightblue'
    return graph

def steps_to_graphviz(tasks, graph):
    for index, task in enumerate(tasks):
        if index > 0:
            graph.add_edge(tasks[index - 1]['name'], task['name'])

    # Change the style of the first node
    node = graph.get_node(tasks[0]['name'])
    node.attr['style'] = 'filled'
    node.attr['fillcolor'] = 'lightblue'
    return graph

def change_extension(filename, new_extension):
    base_name = os.path.splitext(filename)[0]  # Get the base name of the file
    new_filename = base_name + new_extension   # Concatenate the base name with the new extension
    return new_filename

def create_dag(yaml_file, output_file):

    if not os.path.exists(yaml_file):
        print('The YAML file does not exist')
        exit(1)

    with open(yaml_file, 'r') as file:
        data = yaml.safe_load(file)

    if 'entrypoint' not in data['spec']:
        print('The YAML file does not contain an entrypoint.')
        exit(1)

    entrypoint = data['spec']['entrypoint']

    template = next((item for item in data['spec']['templates'] if item['name'] == entrypoint), None )

    graph = pygraphviz.AGraph(directed=True)
    if 'dag' in template:
        print('Creating DAG diagram')
        tasks = template['dag']['tasks']
        for task in tasks:
            graph.add_node(task['name'])
        graph = dag_to_graphviz(tasks, graph)
    elif 'steps' in template:
        print('Creating Steps diagram')
        tasks = flatten_yaml_array(template['steps'])
        for task in tasks:
            graph.add_node(task['name'])
        graph = steps_to_graphviz(tasks, graph)
    else:
        print('The YAML file does not contain a dag or steps.')
        exit(1)
    # Save the graph as a PNG file
    graph.draw(output_file, prog='dot', format='png')
    with open(change_extension(output_file, '.drawio'), 'w') as file:
        file.write(graphviz2drawio.convert(graph))


def main():
    parser = argparse.ArgumentParser(description='Create a diagram of an Argo cluster workflow template dag tasks.')
    parser.add_argument(
        '--input-file',
        dest='input_file',
        required=True,
        type=str,
        help='Path to the YAML input file')
    parser.add_argument(
        '--output-file',
        dest='output_file',
        type=str,
        required=False,
        default='',
        help='Path to the output PNG file. If not specified, the output file will be the same as the input file with the .png extension')

    args = parser.parse_args()
    if args.output_file == '':
        args.output_file = change_extension(args.input_file, '.png')
    create_dag(args.input_file, args.output_file)

if __name__ == '__main__':
    main()
