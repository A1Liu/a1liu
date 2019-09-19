package sort;

// import java.util.LinkedList;
// import java.util.Hashtable;
// import java.util.Iterator;
// import java.util.List;

/**
 * Recursive version of spaghetti sort that relies on compareTo to get
 * "spaghetti lengths"
 * @author Albert Liu
 *
 */
public class SpaghetSorter extends Sorter { // TODO Gimme da Spaghet

  @Override
  protected <T extends Comparable<T>> Accessor<T>
  sort0(Accessor<T> accessor, int startIndex, int endIndex) {
    //		Hashtable<Integer,List<T>> table = new Hashtable<Integer,
    //List<T>>(); 		Iterator<T> iter = list.iterator(); 		T first; 		if
    //(iter.hasNext()) { 			first = iter.next(); 			table.put(0, new LinkedList<T>());
    //			table.get(0).add(first);
    //		}
    //		while(iter.hasNext()) {
    //
    //		}
    return null;
  }
}
