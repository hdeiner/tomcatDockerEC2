package com.deinersoft;

import cucumber.api.java.en.Given;
import cucumber.api.java.en.Then;

import java.io.*;
import java.util.ArrayList;
import java.util.List;
import java.lang.ProcessBuilder;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class Stepdefs {

    private String OS = System.getProperty("os.name").toLowerCase();

    private String tomcat_dns;
    private List<String> remoteNetstatResults;
    private List<String> remoteDockerResults;

    private String getEC2InstanceForTomcat() throws IOException, InterruptedException {
        String tomcat_dns = "";

        Process p = null;
        ProcessBuilder pb = null;
        if (isWindows()) {
            pb = new ProcessBuilder("C:\\Program Files\\Terraform\\terraform.exe", "output", "tomcat_dns");
            pb.directory(new File("C:\\Users\\Howard Deiner\\IdeaProjects\\tomcatDockerEC2\\terraform"));
        } else {
            pb = new ProcessBuilder("/usr/sbin/terraform", "output", "tomcat_dns");
            pb.directory(new File("terraform"));
        }
        p = pb.start();

        BufferedReader stdInput = new BufferedReader(new InputStreamReader(p.getInputStream()));
        BufferedReader stdError = new BufferedReader(new InputStreamReader(p.getErrorStream()));

        String s = null;
        while ((s = stdInput.readLine()) != null) {
            System.out.println("Looking at terraformed " + s);
            tomcat_dns = s;
        }

        while ((s = stdError.readLine()) != null) {
            System.out.println("!!! " + s);
        }

        return tomcat_dns;
    }

    @Given("^I created an \"([^\"]*)\" instance for Tomcat$")
    public void i_created_an_instance_for_Tomcat(String instanceType) throws Throwable {
        tomcat_dns = getEC2InstanceForTomcat();

        String[] cmd = new String[5];
        if (isWindows()) {
            cmd[0] = "C:\\Windows\\System32\\OpenSSH\\ssh.exe";
            cmd[1] = "-o";
            cmd[2] = "StrictHostKeyChecking=no";
            cmd[3] = "ubuntu@"+tomcat_dns;
            cmd[4] = "sudo docker ps";
        } else {
            cmd[0] = "/usr/bin/ssh";
            cmd[1] = "-o";
            cmd[2] = "StrictHostKeyChecking=no";
            cmd[3] = "ubuntu@"+tomcat_dns;
            cmd[4] = "sudo docker ps";
        }
        System.out.println(cmd[0] + " " + cmd[1] + " " + cmd[2] + " " + cmd[3] + " " + cmd[4]);
        remoteDockerResults = runShellCommand(cmd);

        if (isWindows()) {
            cmd[0] = "C:\\Windows\\System32\\OpenSSH\\ssh.exe";
            cmd[1] = "-o";
            cmd[2] = "StrictHostKeyChecking=no";
            cmd[3] = "ubuntu@"+tomcat_dns;
            cmd[4] = "sudo netstat -tulpn";
        } else {
            cmd[0] = "/usr/bin/ssh";
            cmd[1] = "-o";
            cmd[2] = "StrictHostKeyChecking=no";
            cmd[3] = "ubuntu@"+tomcat_dns;
            cmd[4] = "sudo netstat -tulpn";
        }
        System.out.println(cmd[0] + " " + cmd[1] + " " + cmd[2] + " " + cmd[3] + " " + cmd[4]);
        remoteNetstatResults = runShellCommand(cmd);
    }

    @Then("^the instance should be running \"([^\"]*)\" on port \"([^\"]*)\"$")
    public void the_instance_should_be_running_on_port(String arg1, String arg2) throws Throwable {
        assertThat(isProgramRunningOnPort(arg1, arg2), is(true));
    }

    @Then("^Docker should be running image \"([^\"]*)\"$")
    public void docker_should_be_running_image(String arg1) throws Throwable {
        assertThat(remoteDockerResults.get(1).contains(arg1), is(true));
    }

    @Then("^Docker should be redirecting port \"([^\"]*)\" port \"([^\"]*)\" to port \"([^\"]*)\"$")
    public void docker_should_be_redirecting_port_port_to_port(String arg1, String arg2, String arg3) throws Throwable {
        assertThat(remoteDockerResults.get(1).contains(arg3+"->"+arg2+"/"+arg1), is(true));
    }

    @Then("^\"([^\"]*)\" inbound port \"([^\"]*)\" should be open$")
    public void inbound_port_should_be_open(String arg1, String arg2) throws Throwable {
        assertThat(isPortOpen(arg2), is(true));
    }

    private List<String> runShellCommand(String[] command) throws IOException {
        List<String> output = new ArrayList<>();

        Process p = Runtime.getRuntime().exec(command);

        BufferedReader stdInput = new BufferedReader(new InputStreamReader(p.getInputStream()));
        BufferedReader stdError = new BufferedReader(new InputStreamReader(p.getErrorStream()));

        String s = null;
        while ((s = stdInput.readLine()) != null) {
//            System.out.println(s);
            output.add(s);
        }

        while ((s = stdError.readLine()) != null) {
            System.out.println("!!! " + s);
        }

        return output;
    }

    private boolean isProgramRunningOnPort(String programName, String portNumber) {
        boolean result = false;
        for (String s : remoteNetstatResults) {
            String regEx = "^tcp\\d*\\s*\\d*\\s*\\d*\\s*[0127\\.\\:]+" + portNumber + "\\s*[0\\.\\:]+\\*\\s*LISTEN\\s*\\d+\\/" + programName + ".*$";
            result |= s.matches(regEx);
        }
        return result;
    }

    private boolean isPortOpen(String portNumber) throws IOException {
        String[] cmd = new String[4];
        if (isWindows()) {
            cmd[0] = "C:\\Program Files (x86)\\Nmap\\nmap.exe";
            cmd[1] = tomcat_dns;
            cmd[2] = "-p";
            cmd[3] = portNumber;
        } else {
            cmd[0] = "nmap";
            cmd[1] = tomcat_dns;
            cmd[2] = "-p";
            cmd[3] = portNumber;
        }
        List<String> nmapResults = runShellCommand(cmd);
        boolean result = false;
        for (String s : nmapResults) {
            String regEx = "^" + portNumber + ".*open.*$";
            result |= s.matches(regEx);
        }
        return result;
    }

    public boolean isWindows() {
        return (OS.indexOf("win") >= 0);
    }

    public boolean isMac() {
        return (OS.indexOf("mac") >= 0);
    }

    public boolean isUnix() {
        return (OS.indexOf("nix") >= 0 || OS.indexOf("nux") >= 0 || OS.indexOf("aix") > 0 );
    }

    public boolean isSolaris() {
        return (OS.indexOf("sunos") >= 0);
    }
    public String getOS(){
        if (isWindows()) {
            return "win";
        } else if (isMac()) {
            return "osx";
        } else if (isUnix()) {
            return "uni";
        } else if (isSolaris()) {
            return "sol";
        } else {
            return "err";
        }
    }

}
