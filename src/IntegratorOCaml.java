import java.io.File;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

public class IntegratorOCaml {
    private final String _executable;
    private final String _workingDir;

    // Constructor define the OCaml project executable path
    public IntegratorOCaml(String executable, String workingDir) {
        this._executable = executable;
        this._workingDir = workingDir;
    }

    // Check if executable exists
    public boolean verifyExecutable() {
        File f = new File(_executable);

        return f.exists() && !f.isDirectory();
    }
    
    // Execute the command in stdin
    public List<String> executeCommand(String command, String id) {
        // Initialized the array for output data
        List<String> output = new ArrayList<>();

        try {
            // Array of commands
            List<String> fullCommand = new ArrayList<>();

            // Add the path for the OCaml project ex: "../../bin/main.exe"
            fullCommand.add(_executable);

            // Command "listar_alunos" for example
            fullCommand.add(command);

            if (id != null && !id.isEmpty()) {
                // If id is valid add to the command element
                fullCommand.add(id);
            }

            // Initialize stream
            ProcessBuilder pb = new ProcessBuilder(fullCommand);

            // Define the folder to execute the command
            pb.directory(new File(_workingDir));

            pb.redirectErrorStream(true);

            Process process = pb.start();

            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));

            String linha;

            while ((linha = reader.readLine()) != null) {
                output.add(linha);
            }

            process.waitFor();
        } catch (Exception e) {
            output.add("Error while accessing the OCaml module: " + e.getMessage());
        }

        return output;
    }

    public boolean compileOCaml(File compilerFolder, String outputName) {
        try {
            ProcessBuilder pb = new ProcessBuilder(
                    "ocamlc",
                    "-o", outputName,
                    "str.cma",
                    "main.ml"
            );

            // Define the folder to execute the command
            pb.directory(compilerFolder);

            // Redirect errors
            pb.inheritIO();

            Process process = pb.start();

            int exitCode = process.waitFor();

            if (exitCode != 0) {
                System.err.println("Compilação OCaml falhou com código: " + exitCode);

                return false;
            }

            return true;
        } catch (Exception e) {
            System.err.println("Falha ao comunicar com o SO: " + e.getMessage());

            return false;
        }
    }
}