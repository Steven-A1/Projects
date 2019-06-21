"""
Project 6
Canvas Analyzer
CS 1064 Introduction to Programming in Python
Spring 2018

Access the Canvas Learning Management System and process learning analytics.

Edit this file to implement the project.
To test your current solution, run the `test_my_solution.py` file.
Refer to the instructions on Canvas for more information.

"I have neither given nor received help on this assignment."
author: Steven Arbieto
"""
__version__ = 7

import canvas_requests
import matplotlib.pyplot as plt
import datetime

# 1) main
'''
Takes in a string representing the user token and calls all other functions,
such as printing user information and avaliable courses, printing summarizes
of a selected course, and plotting grade trends for a selected course.

Args:
    userID: a string representing the user's token
Returns:
    Nothing
'''
def main(userID):
    
    #--User data portion--#
    userInfo = canvas_requests.get_user(userID)
    
    print_user_info(userInfo)
    
    #--User courses portion--#
    userCourses = canvas_requests.get_courses(userID)
    filteredUserCourses = filter_available_courses(userCourses)
    
    print_courses(filteredUserCourses)
    
    #---Stats / plotting Portion---#
    listOfCourses = get_course_ids(filteredUserCourses)
    chosenCourse = choose_course(listOfCourses)
    userSubmissions = canvas_requests.get_submissions(userID, chosenCourse)
    
    summarize_points(userSubmissions)
    summarize_groups(userSubmissions)
    plot_scores(userSubmissions)
    plot_grade_trends(userSubmissions)
    
# 2) print_user_info
'''
Prints the user's name, title, primary email, and bio via their dictionary.

Args:
    userDict: A dictionary where the user's information is stored.
Returns:
    Nothing
'''
def print_user_info(userDict):
    print('Name:', userDict['name'])
    print('Title:', userDict['title'])
    print('Primary Email:', userDict['primary_email'])
    print('Bio:', userDict['bio'])

# 3) filter_available_courses
'''
Takes in a list of dictionaries and returns a new list of dictionaries where
'workflow_state' is 'available'.

Args:
    listOfCourseDict: a list of Course dictionaries
Returns:
    newListOfDict: a list of Course dictionaries with 'workflow_state' value
                    set to 'available'.
'''
def filter_available_courses(listOfCourseDict):
    filteredListOfDict = []
    for course in listOfCourseDict:
        if course['workflow_state'] == 'available':
            filteredListOfDict.append(course)
    return filteredListOfDict


# 4) print_courses
'''
Takes in a list of Course dictionaries and prints the ID and name of each
course on seperate lines.

Args:
    listOfCourseDict: a list of Course dictionaries
Returns:
    Nothing
'''
def print_courses(listOfCourseDict):
    for course in listOfCourseDict:
        print(str(course['id']) + ':' + course['name'])

# 5) get_course_ids
'''
Takes in a list of Course dicitonaries and returns a list of integers
representing course IDs.

Args:
    listOfCourseDict: a list of Course dictionaries
Return:
    courseIDs: a list of integers representing course IDs.
'''
def get_course_ids(listOfCourseDict):
    courseIDs = []
    for course in listOfCourseDict:
        courseIDs.append(course['id'])
    return courseIDs


# 6) choose_course
'''
Takes in a list of integers representing IDs and acks the user to enter a
valid ID, then returns an integer representing the user's chosen course ID.

If the user does not enter a valid ID, the function loops until they type
a valid ID.

Args:
    listOfCourseIDs: a list of integers representing course IDs
Returns:
    chosenID: integer representing the user's chosen course ID
'''
def choose_course(listOfCourseIDs):
    chosenID = 0
    while(int(chosenID) not in listOfCourseIDs):
        chosenID = input("Enter a valid course ID: ")
    return int(chosenID)


# 7) summarize_points
'''
Takes in a list of Submission dictionaries and prints out three summary
statistics about the submissions where there is a score.

Args:
    listOfSubDict: list of submission dictionaries
Return:
    Nothing
'''
def summarize_points(listOfSubDict):
    #Filtering out submissions that do not have a score(i.e. the None values)
    submissionList = [] # Filtered submission list. Only contains submissions
                        # with a score.
    for submission in listOfSubDict:
        if submission['score'] != None:
            submissionList.append(submission)
    
    #-----Summary statistics-----#

    # Possible points so far   
    print('Points possible so far: ', pointsPossible(submissionList))
    
    # Points obtained
    obtainedPoints = 0
    for submission in submissionList:
        groupWeight = submission['assignment']['group']['group_weight']
        score = submission['score']
        
        obtainedPoints += (score*groupWeight)
    print('Points obtained: ', str(obtainedPoints))
    
    # Current grade
    currentGrade = (obtainedPoints/pointsPossible(submissionList))*100
    print('Current grade: ', str(round(currentGrade)))

'''
Helper function: Calculates the total number of points possible.

Args:
    submissionDictList: a list of dictionaries representing submissions
return:
    points: float value representing points possible so far
'''
def pointsPossible(submissionDictList):
    points = 0.0
    for submission in submissionDictList:
        possPoints = submission['assignment']['points_possible']
        groupWeight = submission['assignment']['group']['group_weight']
        
        points += possPoints*groupWeight
    return points

# 8) summarize_groups
'''
Takes in a list of Submission dictionaries and prints the group name and
unweighted grade for each group.

Args:
    listOfSubDict: a list of submission dictionaries
Returns:
    Nothing
'''
def summarize_groups(listOfSubDict):
    filteredSubList = [] # Filtered submission list. Only contains submissions
                        # with a score.
    for submission in listOfSubDict:
        if submission['score'] != None:
            filteredSubList.append(submission)
    
    # Creating list of total group names from filtered submissions with scores
    groupNames = []
    for submission in filteredSubList:
        assignmentName = submission['assignment']['group']['name']
        
        if assignmentName not in groupNames:
            groupNames.append(assignmentName)
    
    # Nested for loop: 
    # First looks though each group name from groupNames list,
    # then for each name on the list, it goes though each submission from
    # filteredSubList. While looking through each submission, checks to see
    # if that submission matches the group from groupNames, if so, sums up
    # the score and points possible.
    # After summing, a dictionary is created where the keys are the group
    # name and the value assigned to it is a tuple with an integer and a float.
    # The fist value[0] of the tuple is the sum of the score for each group and
    # the second value[1] of the tuple is the sum of the points possible for
    # each group.
    groupSummaries = {}
    for group in groupNames:
        scoreSum = 0
        pointsSum = 0.0
        for submission in filteredSubList:
            assignmentName = submission['assignment']['group']['name']
            pointPoss = submission['assignment']['points_possible']
            
            if group == assignmentName:
                scoreSum += submission['score']
                pointsSum += pointPoss
        groupSummaries[group] = (scoreSum, pointsSum)
    
    # Prints out each group's infromation where:
    # sumsAndPoints are tuples and [0] index is the sum of the scores and 
    # [1] index is the sum of the points possible for that group.
    for group, scoreAndPoint in groupSummaries.items():
        print(group, ':', round((scoreAndPoint[0]/scoreAndPoint[1])*100))
        

# 9) plot_scores
'''
Consumes a list of Submission dictionaries and plots each submission's 
grade as a histogram.

Args:
    listOfSubDict: a list of Submission dictionaries
Return:
    Nothing
'''
def plot_scores(listOfSubDict):
    
    filteredSubs = [] # Filtered submission list. Only contains submissions
                        # with a score and points possible values greater
                        # than zero.
    
    for submission in listOfSubDict:
        possPoints = submission['assignment']['points_possible']
        score = submission['score']
              
        if score != None and possPoints:
            filteredSubs.append(submission)
    
    # Grades are calculated for each submission from filteredSubs list
    # and entered into a list to be plotted
    grades = []
    for submission in filteredSubs:
        possPoints = submission['assignment']['points_possible']
        score = submission['score']
              
        grade = (score/possPoints*100)
        grades.append(grade)

    #Plots grades list as a histogram to show distribution of grades
    plt.hist(grades)
    plt.title('Distribution of Grades')
    plt.xlabel('Grades')
    plt.ylabel('Number of Assignments')
    plt.show()

# 10) plot_grade_trends
'''
Takes in a list of Submission dictionaries and plots the grade trend of the
submissions as a line plot.
The grade trend contains 3 lines (ordered by the assignment's due_at date)
that show you the range of grades you could get in the course: highest, 
lowest, and maximum.

Args:
    listOfSubDict: a list of submission dictionaries
Returns:
    Nothing
'''
def plot_grade_trends(listOfSubDict):
    
    #This function follows the steps 'Reference - Grade Trend' on canvas
    
#---lists of the max, low, and high points for each submission---#
    # if score = None for a submission, lowScore is set to 0 and
    # highScore is set to the number of points possible for that submission
    # otherwise, the scores(low and high) are set to submission score
    maximumPoints = []
    lowestPoints = []
    highestPoints = []
    for submission in listOfSubDict:
        possPoints = submission['assignment']['points_possible']
        groupWeight = submission['assignment']['group']['group_weight']
        score = submission['score']
        
        maxPoints = 100*possPoints*groupWeight
        if score == None:
            lowScore = 0
            highScore = possPoints
        else:
            lowScore = score
            highScore = score
        lowPoints = 100*lowScore*groupWeight
        highPoints = 100*highScore*groupWeight
        
        maximumPoints.append(maxPoints)
        lowestPoints.append(lowPoints)
        highestPoints.append(highPoints)
        
#---caclualting maximum score---#
    maximumScore = 0
    for maxPoint in maximumPoints:
        maximumScore += maxPoint
    maximumScore = maximumScore/100
    
#---Running sums of each: max, low, and high---#
    runningMaxSum = []
    runningSumM = 0
    for point in maximumPoints:
        runningSumM += point
        runningMaxSum.append(round(runningSumM/maximumScore, 2))
        
    runningLowSum = []
    runningSumL = 0
    for point in lowestPoints:
        runningSumL += point
        runningLowSum.append(round(runningSumL/maximumScore, 2))
        
    runningHighSum = []
    runningSumH = 0
    for point in highestPoints:
        runningSumH += point
        runningHighSum.append(round(runningSumH/maximumScore, 2))
        
#---Fetching 'due_at' dates from submissions---#
    dueDates = []
    for submission in listOfSubDict:
        stringDate = submission['assignment']['due_at']
        due_at = datetime.datetime.strptime(stringDate, '%Y-%m-%dT%H:%M:%SZ')
        dueDates.append(due_at)
    
#---Ploting data---#
    plt.plot(dueDates, runningHighSum, label='Highest')
    plt.plot(dueDates, runningLowSum, label='Lowest')
    plt.plot(dueDates, runningMaxSum, label='Maximum')
    plt.xticks(rotation=45)
    plt.legend()
    plt.ylabel('Grade')
    plt.title('Grade Trend')
    plt.show()
    

# Keep any function tests inside this IF statement to ensure
# that your `test_my_solution.py` does not execute it.
if __name__ == "__main__":
    main('hermione')
    # main('ron')
    # main('harry')
    
    # https://community.canvaslms.com/docs/DOC-10806-4214724194
#main('4511~RdNwBH5qhWDmbvBwoJBj5xAEb5xo2cIpxa3rvYm06M7ucsYoRXcKz6b6I3Wq8Pc3')