# Compiler and flags
CXX = g++
CXXFLAGS = -std=c++20 -g -Wall

# Source files and object files
SRCS = YoMath.cpp Render.cpp Video.cpp Esfera.cpp Scene.cpp Objects.cpp Plano.cpp Surface.cpp Lampada.cpp RayTest.cpp
OBJS = $(SRCS:.cpp=.o)

# Output binary
TARGET = render

# Default target
all: $(TARGET)

# Link all object files into the final executable
$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) $(OBJS) -o $(TARGET)

# Compile each .cpp file into a .o file
%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Clean rule to remove compiled files
clean:
	rm -f $(OBJS) $(TARGET)

