import csv

def analyze_csv(file_path, threshold):
    with open(file_path, 'r') as f:
        reader = csv.reader(f)
        next(reader)  
        for row in reader:
            name, age, *grades = row
            grades = list(map(float, grades))  
            average_grade = sum(grades) / len(grades)  # Calculate average
            if average_grade > threshold:
                print(f"{name} has average above {threshold}")

# Example usage:
analyze_csv('students.csv', 75.0)
