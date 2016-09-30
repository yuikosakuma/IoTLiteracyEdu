int sortType = 0;

public class NodeComparatorByNodeid implements Comparator<Node> { 
  @Override public int compare(Node p1, Node p2) { 
    return p1.nodeid < p2.nodeid ? -1 : 1;
  }
} 

public class NodeComparatorByTemperature implements Comparator<Node> { 
  @Override public int compare(Node p1, Node p2) { 
    return p1.temperature > p2.temperature ? -1 : 1;
  }
} 

public class NodeComparatorByVotedcounter implements Comparator<Node> { 
  @Override public int compare(Node p1, Node p2) { 
    return p1.votedcounter > p2.votedcounter ? -1 : 1;
  }
} 

void changeSortType() {
  //for sort
  switch(sortType) {
  case 1: //Temperature
    //destructive sort
    Collections.sort(nodes, new NodeComparatorByTemperature()); 
    break;
  case 2: //VotedCounter
    //destructive sort
    Collections.sort(nodes, new NodeComparatorByVotedcounter());   
    break;
  default: //nodeid
    //destructive sort
    Collections.sort(nodes, new NodeComparatorByNodeid()); 
    break;
  }
}

void displaySortType(float x, float y) {
  fill(255);
  textAlign();
  textSize(height / 20);
  String temp_str = "Sorted by: ";
  switch(sortType) {
  case 1:
    temp_str += "Temperature";
    break;
  case 2:
    temp_str += "Voted count";
    break;
  default:
    temp_str += "Node ID";
    break;
  }
  text(temp_str, x, y);
}

//// ---------------------- Example ---------------------
////refer to http://java.keicode.com/lib/collections-sort.php
//
//import java.util.ArrayList; 
//import java.util.Collections; 
//
//void setup() {
//  ArrayList<Person> memberList = new ArrayList<Person>(); 
//  memberList.add(new Person(40, "Hanako")); 
//  memberList.add(new Person(50, "Taro")); 
//  memberList.add(new Person(20, "Ichiro")); 
//  for (int i=0; i<memberList.size (); i++) { 
//    System.out.format("%s - %d\n", memberList.get(i).name, memberList.get(i).age);
//  } 
//  Collections.sort(memberList, new PersonComparator()); 
//  System.out.println("--- Sorted ---"); 
//  for (int i=0; i<memberList.size (); i++) { 
//    System.out.format("%s - %d\n", memberList.get(i).name, memberList.get(i).age);
//  }
//}
//
//public class Person { 
//  public int age; 
//  public String name; 
//  public Person(int age, String name) { 
//    this.age = age; 
//    this.name = name;
//  }
//} 
//
//import java.util.Comparator; 
//public class PersonComparator implements Comparator<Person> { 
//  @Override public int compare(Person p1, Person p2) { 
//    return p1.age < p2.age ? -1 : 1;
//  }
//} 

