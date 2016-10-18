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
  textAlign(LEFT);
  textSize(height / 20);
  String temp_str = "Sorted by:\n";
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

void displayTempRanking(float x, float y) {
  fill(255);
  textAlign(LEFT);
  textSize(height / 25);
  ArrayList<Node> tempList = new ArrayList<Node>(nodes);
  Collections.sort(tempList, new NodeComparatorByTemperature()); 
  String temp_str = "Temp Rank\n"
    + "1st: " + tempList.get(0).temperature + " " + tempList.get(0).name.trim() + "\n"
    + "2nd: " + tempList.get(1).temperature + " " + tempList.get(1).name.trim() + "\n"
    + "3rd: " + tempList.get(2).temperature + " " + tempList.get(2).name.trim() + "\n";
  text(temp_str, x, y);
}

void displayVCRanking(float x, float y) {
  fill(255);
  textAlign(LEFT);
  textSize(height / 25);
  ArrayList<Node> tempList = new ArrayList<Node>(nodes);
  Collections.sort(tempList, new NodeComparatorByVotedcounter()); 
  String temp_str = "#Voted Rank\n"
    + "1st: " + tempList.get(0).votedcounter + " " + tempList.get(0).name.trim() + "\n"
    + "2nd: " + tempList.get(1).votedcounter + " " + tempList.get(1).name.trim() + "\n"
    + "3rd: " + tempList.get(2).votedcounter + " " + tempList.get(2).name.trim() + "\n";
  text(temp_str, x, y);
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