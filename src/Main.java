import java.io.File;

public class Main {

    public static void main(String[] args) {
        String rootPath = System.getProperty("user.dir");

        String baseFolderName = "bin";

        String executableName = "main.exe";

        String binDirPath = rootPath + File.separator + "bin";

        String ocamlFolderPath = rootPath + File.separator + "ocaml";

        String completeExecutablePath = binDirPath + File.separator + "main.exe";

        File compileDir = new File(ocamlFolderPath);

        IntegratorOCaml integrator = new IntegratorOCaml(completeExecutablePath, binDirPath);

        if (!integrator.verifyExecutable()) {
            System.err.println("Erro: Executável OCaml não encontrado em: " + completeExecutablePath);

            boolean success = integrator.compileOCaml(compileDir, executableName);

            System.out.println("Compilando [" + executableName + "] na pasta [" + baseFolderName + "]..., Reinicie novamente a aplicação");

            if (!success) {
                System.err.println("Erro: Não foi possível criar o executável OCaml.");

                return;
            }

            return;
        }

        Interface ui = new Interface(integrator);

        ui.start();
    }
}