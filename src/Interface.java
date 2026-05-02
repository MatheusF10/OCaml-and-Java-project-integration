import java.util.Scanner;
import java.util.List;

public class Interface {
    private final IntegratorOCaml _integrator;
    private final Scanner _scanner;

    public Interface(IntegratorOCaml integrator) {
        this._integrator = integrator;
        this._scanner = new Scanner(System.in);
    }

    public void start() {
        boolean running = true;

        while (running) {
            System.out.println("\n========= INTERFACE DE GESTÃO =========");
            System.out.println("1. Listar Todos os Alunos");
            System.out.println("2. Ver Indicadores (Notas/Assiduidade)");
            System.out.println("3. Avaliar Aluno (Regras R1-R4)");
            System.out.println("4. Listar Estados Finais (Ordenado)");
            System.out.println("0. Sair");
            System.out.print("\nOpção: ");

            String option = _scanner.nextLine().trim();

            switch (option) {
                case "1":
                    handleRequest("listar_alunos", false);
                    break;
                case "2":
                    handleRequest("indicadores", true);
                    break;
                case "3":
                    handleRequest("avaliar", true);
                    break;
                case "4":
                    handleRequest("listar_estados", false);
                    break;
                case "0":
                    System.out.println("A encerrar...");
                    running = false;
                    break;
                default:
                    System.out.println("\n[Erro] Opção inválida.");
            }
        }
    }

    private void handleRequest(String command, boolean needsId) {
        String id = null;

        if (needsId) {
            System.out.print("Introduza o ID do aluno: ");

            id = _scanner.nextLine().trim();

            if (!id.matches("\\d+")) {
                System.out.println("\n[Erro] O ID deve ser um número inteiro.");

                return;
            }
        }

        List<String> result = _integrator.executeCommand(command, id);

        renderOutput(result);
    }

    private void renderOutput(List<String> lines) {
        System.out.println("\n--- Resposta do Sistema ---");

        if (lines.isEmpty()) {
            System.out.println("Sem dados.");

            return;
        }

        lines.forEach(line -> System.out.println(" > " + line));

        System.out.println("---------------------------");
    }
}