import java.math.BigInteger;

public interface Ports
{
 public void out(int addr,int data, BigInteger clocks);
 public int in(int addr, BigInteger clocks);
}