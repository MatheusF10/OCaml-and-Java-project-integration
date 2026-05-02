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
    
    public List<String> executeCommand(String command, String id) {
    List<String> output = new ArrayList<>();

    try {
        List<String> fullCommand = new ArrayList<>();

        fullCommand.add(_executable);

        fullCommand.add("../ocaml/database_26.pl");
        
        fullCommand.add(command);

        if (id != null && !id.isEmpty()) {
            fullCommand.add(id);
        }

        ProcessBuilder pb = new ProcessBuilder(fullCommand);
        pb.directory(new File(_workingDir));

        // Keep stderr separate (for debug control)
        pb.redirectErrorStream(true);

        Process process = pb.start();

        // Read output safely
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream()))) {

            String line;
            while ((line = reader.readLine()) != null) {
                output.add(line);
            }
        }

        int exitCode = process.waitFor();

        // Handle failure explicitly
        if (exitCode != 0) {
            output.add("ERROR: OCaml process failed with code " + exitCode);
        }

    } catch (Exception e) {
        output.add("Error while accessing OCaml module: " + e.getMessage());
    }

    return output;
}

    public boolean compileOCaml(File compilerFolder, String outputName) {
        try {
            // Ensure bin exists
            File binDir = new File(compilerFolder.getParentFile(), "bin");

            if (!binDir.exists()) {
                boolean created = binDir.mkdirs();

                if (!created) {
                    System.err.println("Falha ao criar diretório bin/");
                    return false; // ou throw
                }
            }

            File compilerFile = new File(compilerFolder.getAbsoluteFile(), "main.ml");

            ProcessBuilder pb = new ProcessBuilder(
                    "ocamlc",
                    "-o", outputName,
                    "str.cma",
                    compilerFile.getPath()
            );

            // Define the folder to execute the command
            pb.directory(binDir);

            // Redirect errors
            pb.redirectErrorStream(true);

            Process process = pb.start();

            int exitCode = process.waitFor();

            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream())
            );

            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println("[OCAML] " + line);
            }

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