#! /usr/bin/python

import sys, re

def get_pre_actions(package:str):
    return f"""
	sed "s|@ACTUAL_PACKAGE@|{package}|" $(BUILD_TOOLS)/cc-wrapper.sh > $(BUILD_TOOLS)/{package}-cc-wrapper.sh
	sed "s|@ACTUAL_PACKAGE@|{package}|" $(BUILD_TOOLS)/cxx-wrapper.sh > $(BUILD_TOOLS)/{package}-cxx-wrapper.sh
	chmod +x $(BUILD_TOOLS)/{package}-cc-wrapper.sh
	chmod +x $(BUILD_TOOLS)/{package}-cxx-wrapper.sh
	rm -f $(BUILD_WORK)/{package}/.install_name_cache"""
 
def get_post_actions(package:str):
    return f"""\trm -f $(BUILD_TOOLS)/{package}-cc-wrapper.sh
	rm -f $(BUILD_TOOLS)/{package}-cxx-wrapper.sh"""

def get_file_content(package:str, cache:dict[str]):
    fileContent = ""
    if package in cache:
        fileContent = cache[package]
    else:
        file = open(f"makefiles/{package}.mk", "r")
        fileContent = file.read()
        cache[package] = fileContent
        file.close()
    return fileContent

def get_header(package:str, cache:dict[str]):
    fileContent = get_file_content(package, cache)
    return re.findall(fr"{package}:.*", fileContent)[-1]

def get_modified_header(header:str, package:str):
    deps = header[len(f"{package}: {package}-setup "):].split(" ")
    if deps != [""]:
        for i in range(len(deps)):
            deps[i] += "-ios"
    cc_asignement = f"{package}-ios: CC = $(BUILD_TOOLS)/{package}-cc-wrapper.sh\n"
    cxx_asignement = f"{package}-ios: CXX = $(BUILD_TOOLS)/{package}-cxx-wrapper.sh\n"
    header = " ".join([f"{package}-ios: {package}-setup"] + deps)
    return cc_asignement + cxx_asignement + header


# Recursively calcs the dependencies of each package
def calc_deps(package:str, deps:list[str], cache:dict[str]):
    packageDeps = get_header(package, cache)[len(f"{package}: {package}-setup "):].split(" ")
    if packageDeps == [""]:
        return []
        
    for dep in packageDeps:
        deps += calc_deps(dep, deps, cache)
    updatedDeps = list(dict.fromkeys(deps + packageDeps)) # remove duplicated entries
    print(package + ":", updatedDeps)
    return updatedDeps

def get_recipe(package:str, cache:dict[str]):
    fileContent = get_file_content(package, cache)
    recipeHeader = get_header(package, cache)
    return re.findall(fr"(?<={recipeHeader}\n)(?:\t.*(?:\n|$))+", fileContent)[0]

def get_check_if_already_built(package:str):
    return f"""ifneq ($(wildcard $(BUILD_WORK)/{package}/.build_complete),)
{package}-ios:
	@echo "Using previously built {package}."
else"""

if __name__ == "__main__":

    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <package-name>")
        exit(1)

    filesCache = {}
    fileString = """"""

    # Calc the dependencies
    deps = calc_deps(sys.argv[1], [], filesCache)
    toBuild = [sys.argv[1]] + deps

    # Build the .mk file
    for package in toBuild:
        fileString += get_check_if_already_built(package)
        fileString += '\n'
        fileString += get_modified_header(get_header(package, filesCache), package)
        fileString += get_pre_actions(package)
        fileString += '\n'
        fileString += get_recipe(package, filesCache)
        fileString += get_post_actions(package)
        fileString += '\n'
        fileString += "endif\n\n"

    # Save to file
    file = open("makefiles/ios-rules.mk", "w")
    file.write(fileString)
    file.close()