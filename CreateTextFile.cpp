#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>
#include <windows.h>

namespace fs = std::filesystem;
std::string version = "0.0.2";

// Check if file exists
bool fileExists(const std::string& filename) {
    return fs::exists(filename);
}

// Generate new filename if original exists
std::string generateNewFilename(const std::string& baseName) {
    std::string newName = baseName;
    int counter = 1;
    
    while (fileExists(newName)) {
        size_t dotPos = baseName.find_last_of('.');
        if (dotPos != std::string::npos) {
            std::string nameWithoutExt = baseName.substr(0, dotPos);
            std::string extension = baseName.substr(dotPos);
            newName = nameWithoutExt + " (" + std::to_string(counter) + ")" + extension;
        } else {
            newName = baseName + " (" + std::to_string(counter) + ")";
        }
        counter++;
    }
    
    return newName;
}

// Create text file
bool createTextFile(const std::string& filename, const std::string& content = "") {
    try {
        std::ofstream file(filename, std::ios::out);
        if (!file.is_open()) {
            std::cerr << "Error: Cannot create file " << filename << std::endl;
            return false;
        }
        
        if (!content.empty()) {
            file << content;
        }
        
        file.close();
        std::cout << "Created file: " << filename << std::endl;
        return true;
    }
    catch (const std::exception& e) {
        std::cerr << "Error creating file: " << e.what() << std::endl;
        return false;
    }
}

// Get current directory
std::string getCurrentDirectory() {
    char buffer[MAX_PATH];
    GetCurrentDirectoryA(MAX_PATH, buffer);
    return std::string(buffer);
}

// Show version information
void showVersion() {
    // std::cout << "CreateFile Utility - Version 1.0.0" << std::endl;
    std::cout << "CreateFile Utility - Version " << version << std::endl;
    std::cout << "A simple tool for creating text files without extensions" << std::endl;
}

// Show usage information
void showUsage() {
    std::cout << "Source code at https://github.com/NiZhaZi/File-Creator\n";
    std::cout << "CreateFile - Create extensionless text files\n\n";
    std::cout << "Usage:\n";
    std::cout << "  CreateFile [options] [filename] [content]\n";
    std::cout << "  Or run without parameters to create default file\n\n";
    std::cout << "Options:\n";
    std::cout << "  --version          Show version information\n";
    std::cout << "  --help             Show this help message\n";
    std::cout << "  --name <filename>  Specify filename (with or without extension)\n";
    std::cout << "  --content <text>   Specify file content\n\n";
    std::cout << "Examples:\n";
    std::cout << "  CreateFile                            # Create default extensionless file\n";
    std::cout << "  CreateFile --version                 # Show version\n";
    std::cout << "  CreateFile --name document.txt       # Create specific file\n";
    std::cout << "  CreateFile --name notes --content \"Hello World\"  # Create file with content\n";
    std::cout << "  CreateFile myfile \"File content\"    # Traditional usage (backward compatible)\n";
}

// Parse command line arguments
bool parseArguments(int argc, char* argv[], std::string& filename, std::string& content) {
    // If no arguments, use default behavior
    if (argc == 1) {
        filename = generateNewFilename("file");
        return true;
    }
    
    // Check for help or version flags
    std::string firstArg = argv[1];
    if (firstArg == "--help" || firstArg == "-h") {
        showUsage();
        return false;
    }
    
    if (firstArg == "--version" || firstArg == "-v") {
        showVersion();
        return false;
    }
    
    // Parse named arguments
    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        
        if (arg == "--name" && i + 1 < argc) {
            filename = generateNewFilename(argv[++i]);
        }
        else if (arg == "--content" && i + 1 < argc) {
            content = argv[++i];
        }
        else if (arg == "--help" || arg == "-h") {
            showUsage();
            return false;
        }
        else if (arg == "--version" || arg == "-v") {
            showVersion();
            return false;
        }
        else if (i == 1 && arg[0] != '-') {
            // Backward compatibility: first non-option argument is filename
            filename = generateNewFilename(arg);
            
            // Collect remaining arguments as content
            for (int j = 2; j < argc; j++) {
                content += argv[j];
                if (j < argc - 1) content += " ";
            }
            break;
        }
        else if (arg[0] == '-') {
            std::cerr << "Error: Unknown option '" << arg << "'" << std::endl;
            showUsage();
            return false;
        }
    }
    
    // If no filename specified with --name, use default
    if (filename.empty()) {
        filename = generateNewFilename("file");
    }
    
    return true;
}

int main(int argc, char* argv[]) {
    // Set console output to UTF-8 for international characters
    SetConsoleOutputCP(CP_UTF8);
    
    std::string filename;
    std::string content;
    
    // Parse command line arguments
    if (!parseArguments(argc, argv, filename, content)) {
        return 0;
    }
    
    std::cout << "Current directory: " << getCurrentDirectory() << std::endl;
    std::cout << "Creating file: " << filename << std::endl;
    
    if (createTextFile(filename, content)) {
        // Optional: ask to open file
        char choice = 'n';
        if (choice == 'y' || choice == 'Y') {
            ShellExecuteA(NULL, "open", filename.c_str(), NULL, NULL, SW_SHOW);
        }
        
        return 0;
    } else {
        return 1;
    }
}