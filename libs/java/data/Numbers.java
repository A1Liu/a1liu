package data;

import java.util.Arrays;
import java.util.Iterator;
import java.util.LinkedList;

public class Numbers {

  private Numbers() {}

  /**
   *
   * @param min
   * @param max
   * @return
   */
  public static int randomWithRange(int min, int max) {
    return (int)(Math.random() * ((max - min) + 1)) + min;
  }

  /**
   * Generates primes. Create a PrimeGenerator Object to get primes. Object
   * iterates through a static series. First 25 primes are pre-loaded
   *
   * @author Albert Liu
   *
   */
  public static class PrimeGenerator { // This class tries to use dynamic
                                       // programming to reduce the amount of
                                       // work that the computer has to do to get
                                       // all dem primes.
    public volatile static int[] primes;
    private volatile int index;
    private static final int LARGEST_PRIME_POSSIBLE = Integer.MAX_VALUE;
    private static final double BOUND_POWER =
        1.5; // An approximation of the highest number that needs to be tested
             // to find all the primes

    static {
      primes = new int[] {
          2,  3,  5,  7,  11, 13, 17, 19, 23, 29, 31, 37, 41,
          43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97}; // First 25 primes.
    }

    /**
     * Create a prime generator that starts a a specific prime
     * @param index index to start
     */
    public PrimeGenerator(int index) { this.index = index; }

    /**
     * Create a prime generator starting at the first prime
     */
    public PrimeGenerator() { this(0); }

    public synchronized int getPrime(int index) {
      if (index >= primes.length)
        fillPrimes(Math.max((int)(primes.length * 1.5), index));
      else if (index < 0)
        index = 0;
      return primes[index];
    }

    /**
     * Returns the current prime in the sequence and goes forwards 1
     * @return the next prime number
     */
    public synchronized int nextPrime() { return getPrime(index++); }

    /**
     * Returns the previous prime in the sequence and goes back 1
     * @return the previous prime number
     */
    public synchronized int prevPrime() {
      if (index <= 0)
        index = 1;
      return getPrime(--index);
    }

    /**
     * Returns the value of n, which represents the amount of prime numbers less
     * than or equal to the prime number that this generator is on. <br> For
     * example, if the generator is on the prime '2', then n would equal 1.
     * @return the value of n
     */
    public int getN() { return index + 1; }

    /**
     * Returns all the primes less than or equal to the nth prime.
     * @param n specified number of primes
     * @return an array of prime integers
     */
    public static int[] primeList(int n) { return primeList(0, n); }

    /**
     * Returns all primes in the static list of primes between the begin and end
     * index (includes begin but does not include end.) If end is greater than
     * the length of the list of primes, the list of primes calculates enough
     * primes to expand the list, until either <code>primes.length == end</code>
     * or the last value in <code>primes<code> is equal to
     * <code>Integer.MAX_VALUE</code>
     * @param begin begin index
     * @param end end index
     * @return an array of prime integers
     * @throws ArrayIndexOutOfBoundsException - if begin < 0 or begin >
     *     original.length
     * @throws IllegalArgumentException - if begin > end
     */
    public static int[] primeList(int begin, int end)
        throws ArrayIndexOutOfBoundsException, IllegalArgumentException {
      if (end > primes.length)
        fillPrimes(end);
      return Arrays.copyOfRange(primes, begin, end);
    }

    /**
     * Over-estimates the value of the nth prime
     * @param n the number of the prime to estimate
     * @return the estimation of the nth prime
     */
    public static int estimateNth(
        int n) { // This can be improved. Every improvement to this method
                 // improves runtime by reducing the number of required checks
      return (int)Math.pow(n, BOUND_POWER); // PNT is around nlog(n), so should
                                            // try to overestimate this function
    }

    /**
     * Fills the array of primes from the specified initial index
     * @param endSize the new size of the array
     */
    private static synchronized void fillPrimes(int endSize) {
      int largestPrime = primes[primes.length - 1];
      if (largestPrime == LARGEST_PRIME_POSSIBLE) // Stop if the array is
                                                  // already as big as possible
        return;
      int numPrimes = primes.length;
      int limit = Math.min(
          estimateNth(endSize),
          LARGEST_PRIME_POSSIBLE); // limit is the highest number checked. Only
                                   // checks up to limit for ints
      LinkedList<Integer> newPrimes = new LinkedList<Integer>();
      boolean composite[] =
          new boolean[limit - largestPrime + 1]; // starts as false
      for (int current = 0; current <= limit;
           current++) { // current begins as an index, then transitions to a
                        // number
        if (current < numPrimes) { // current is an index
          boolean flag = false;
          int currentPrime = primes[current];
          for (int index = 0; index < composite.length;) {
            if (flag || (index + largestPrime) % currentPrime == 0) {
              composite[index] = true;
              flag = true;
              index += currentPrime;
            } else
              index++;
          }
        } else if (current == numPrimes) { // current becomes a number
          current = largestPrime - 1;
        } else { // current is a number
          if (!composite[current - largestPrime]) {
            newPrimes.add(current);
            boolean flag = false;
            for (int index = 0; index < composite.length;) {
              if (flag || (index + largestPrime) % current == 0) {
                composite[index] = true;
                flag = true;
                index += current;
              } else
                index++;
            }
          }
        }
      }
      primes = Arrays.copyOf(primes, primes.length + newPrimes.size());
      Iterator<Integer> iterator = newPrimes.iterator();
      for (int fillIndex = numPrimes; fillIndex < primes.length;
           fillIndex++) { // Repopulate the primes array with the new primes
        primes[fillIndex] = iterator.next();
      }
    }
  }
}
