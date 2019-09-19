package commands.simple;

import commands.Command;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.LinkedList;

/**
 *
 * Takes inputs and traverses command graph using them.
 * TODO Need to make this
 *
 * @author aliu
 *
 */
public abstract class SimpleCommands {

  private BufferedReader reader;
  private LinkedList<Node> commands;
  public SimpleCommands() {
    reader = new BufferedReader(new InputStreamReader(System.in));
    commands = new LinkedList<Node>();
  }

  public String getRawInput() throws IOException { return reader.readLine(); }

  public String[] getInput() throws IOException {
    return getRawInput().split("\\s+");
  }

  public void addCommand(Command command, String... strings) {
    commands.add(new Node(command, strings));
  }

  public void addCommand(String[] strings, Command command) {
    commands.add(new Node(command, strings));
  }

  public void execute(String input) {}

  private static class Node {
    String[] commandString;
    Command command;
    Node(Command command, String[] commandString) {
      this.commandString = commandString;
      this.command = command;
    }
  }
}
