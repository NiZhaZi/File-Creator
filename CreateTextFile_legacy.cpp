#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>
#include <windows.h>

namespace fs = std::filesystem;

// Check if file exists
bool fileExists(const std::string& filename) {
    return fs::exists(filename);
}

// Generate new filename if original exists
std::string generateNewFilename(const std::string& baseName) {
    std::string newName = baseName;
    int counter = 1;
    
    while (fileExists(newName)) {
        newName = baseName + " (" + std::to_string(counter) + ")";
        counter++;
    }
    
    return newName;
}

// Create extensionless text file
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

// Show usage information
void showUsage() {
    std::cout << "Usage:\n";
    std::cout << "  CreateTextFile [filename] [content]\n";
    std::cout << "  Or run without parameters to create default file\n\n";
    std::cout << "Examples:\n";
    std::cout << "  CreateTextFile mydocument \"This is file content\"\n";
    std::cout << "  CreateTextFile notes\n";
}

int main(int argc, char* argv[]) {
    // Set console output to UTF-8 for international characters
    SetConsoleOutputCP(CP_UTF8);
    
    std::string filename;
    std::string content;
    
    if (argc == 1) {
        // No parameters: create default file
        filename = generateNewFilename("file");
        content = "This is an extensionless text file\nCreated: " + std::string(__DATE__) + " " + std::string(__TIME__);
    }
    else if (argc == 2) {
        // One parameter: use as filename
        filename = generateNewFilename(argv[1]);
        content = "File: " + filename + "\nCreated: " + std::string(__DATE__) + " " + std::string(__TIME__);
    }
    else {
        // Multiple parameters: first is filename, rest is content
        filename = generateNewFilename(argv[1]);
        for (int i = 2; i < argc; i++) {
            content += argv[i];
            if (i < argc - 1) content += " ";
        }
    }

    content = "";
    
    std::cout << "Current directory: " << getCurrentDirectory() << std::endl;
    std::cout << "Creating file: " << filename << std::endl;
    
    if (createTextFile(filename, content)) {
        // std::cout << "✓ File created successfully!" << std::endl;
        
        // Optional: ask to open file
        // std::cout << "Open file? (y/n): ";
        char choice;
        // std::cin >> choice;
        
        choice = 'n';
        if (choice == 'y' || choice == 'Y') {
            ShellExecuteA(NULL, "open", filename.c_str(), NULL, NULL, SW_SHOW);
        }
        
        return 0;
    } else {
        // std::cerr << "✗ Failed to create file!" << std::endl;
        return 1;
    }
}