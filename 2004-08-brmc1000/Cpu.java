

public interface Cpu
{
 public void run(int nbCycles);
 public void start();
 public void stop();
 public void reset(int startAddr);
}