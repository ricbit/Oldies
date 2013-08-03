#include <cstdio>
#include <cstdlib>
#include <vector>
#include <string>
#include <cmath>
#include <algorithm>
#include <future>

using namespace std;

struct Image {
  int h, w;
  vector<vector<int>> pix;
  Image(int h_, int w_) : h(h_), w(w_), pix(h, vector<int>(w, 0)) {
  }
  Image(const string& name) {
    auto f = fopen(name.c_str(), "rt");
    char dummy[256];
    fscanf(f, "%s", dummy);
    fscanf(f, "%d %d", &h, &w);
    int max_color;
    fscanf(f, "%d", &max_color);
    pix.resize(h, vector<int>(w));
    for (int j = 0; j < h; j++) {
      for (int i = 0; i < w; i++) {
        fscanf(f, "%d", &pix[j][i]);
      }
    }
  }
};

typedef pair<double, double> Point;

template<typename T>
T sqr(T x) {
  return x * x;
}

template<typename T>
T dist(T y, T x, int index, const vector<Point>& point_list, const vector<double>& weight) {
  return (sqr(y - point_list[index].first) + 
          sqr(x - point_list[index].second)) * weight[index];
}

int nearest(double y, double x, const vector<Point>& point_list, const vector<double>& weight) {
  int best_index = 0;
  double best_value = dist(y, x, 0, point_list, weight);
  for (size_t i = 1; i < point_list.size(); i++) {
    double d = dist(y, x, i, point_list, weight);
    if (d < best_value) {
      best_value = d;
      best_index = i;
    }
  }
  return best_index;
}

struct Voronoi {
  int size, points;
  vector<Point> point_list;
  vector<double> weight;
  const Image& source;

  Voronoi(int size_, const Image& source_) 
      : size(size_), points(0), source(source_) {
    double pmax = 0.2;
    for (int j = 0; j < size; j++) {
      for (int i = 0; i < size; i++) {
        if (drand() < pmax - pmax * source.pix[j][i] / 255.0) {        
          point_list.push_back(make_pair(
              j + (rand() % 20 - 10), i + (rand() % 20 - 10)));
          points++;
        }
      }
    }
    printf("points %d\n", points);
    random_shuffle(point_list.begin(), point_list.end());
    weight.resize(points, 1.0);
  }
 
  double drand() {
    return double(rand()) / RAND_MAX;
  }

  Image generate() {
    Image im(size, size);
    vector<double> accx(points, 0), accy(points, 0);
    vector<double> count(points, 0);
    vector<double> mean(points, 0);
    vector<future<vector<int>>> threads;
    for (int j = 0; j < size; j++) {
      threads.push_back(async(launch::async, [j, this]() {
        vector<int> color(this->size);
        for (int i = 0; i < this->size; i++) {
          color[i] = nearest(j, i, this->point_list, this->weight);
        }
        return color;
      }));
    }
    for (int j = 0; j < size; j++) {
      vector<int> color_list = threads[j].get();
      for (int i = 0; i < size; i++) {
        int color = color_list[i];
        im.pix[j][i] = color;
        accy[color] += j;
        accx[color] += i;
        count[color]++;
        mean[color] += source.pix[j][i];
      }
    }
    for (int i = 0; i < points; i++) {
      if (count[i]) {
        point_list[i].first = accy[i] / count[i];
        point_list[i].second = accx[i] / count[i];
        weight[i] = 1 + pow(255.0 - (mean[i] / count[i]), 2);
      } else {
        point_list[i].first = size * 2;
        point_list[i].second = size * 2;
        weight[i] = 1e12;
      }
      printf("%lf ", weight[i]);
    }
    printf("\n");
    return im;
  }

  int clamp(double x) {
    return x < 0.0 ? 0 : x >= size ? size - 1 : int(x);
  }

  void save(const Image& image, const string& name) {
    vector<vector<int>> dots(size, vector<int>(size, points));
    for (int i = 0; i < points; i++) {
      dots[clamp(point_list[i].first)][clamp(point_list[i].second)] = 0;
    }
    auto f = fopen(name.c_str(), "wt");
    fprintf(f, "P2\n");
    fprintf(f, "%d %d\n%d\n", image.w * 2, image.h, points);
    for (int j = 0; j < image.h; j++) {
      for (int i = 0; i < image.w; i++) {
        fprintf(f, "%d ", image.pix[j][i]);
      }
      for (int i = 0; i < image.w; i++) {
        fprintf(f, "%d ", dots[j][i]);
      }
      fprintf(f, "\n");
    }
  }

};

int main() {
  Image source("marilyn.pgm");
  Voronoi v(300, source);
  for (int i = 0; i < 10; i++) {
    Image im = v.generate();
    char str[100];
    sprintf(str, "image%03d.ppm", i);
    v.save(im, str);
  }
  return 0;
}
