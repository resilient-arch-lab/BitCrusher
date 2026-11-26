// Automatically generated C++ file on Wed Nov 25 16:45:58 2026
//
// To build with Digital Mars C++ Compiler: 
//
//    dmc -mn -WD -o flyback_x1.cpp kernel32.lib

#include <malloc.h>

extern "C" __declspec(dllexport) void (*bzero)(void *ptr, unsigned int count)   = 0;

union uData
{
   bool b;
   char c;
   unsigned char uc;
   short s;
   unsigned short us;
   int i;
   unsigned int ui;
   float f;
   double d;
   long long int i64;
   unsigned long long int ui64;
   char *str;
   unsigned char *bytes;
};

// int DllMain() must exist and return 1 for a process to load the .DLL
// See https://docs.microsoft.com/en-us/windows/win32/dlls/dllmain for more information.
int __stdcall DllMain(void *module, unsigned int reason, void *reserved) { return 1; }

// #undef pin names lest they collide with names in any header file(s) you might include.
#undef DRIVE
#undef SET
#undef CS
#undef VS
#undef CLK

struct sPID {
   double KP, KI, KD;
   double err[2];
   double I;
   double dt;
};

struct sFLYBACK_X1
{
  bool stepped;
  double t_prev;
  sPID pid;
};

void init_pid(struct sPID *pid, double KP, double KI, double KD) {
   pid->KP = KP;
   pid->KI = KI;
   pid->KD = KD;
   pid->err[0] = 0;
   pid->err[1] = 0;
   pid->I = 0;
   pid->dt = 0;
}

void init_sFLYBACK_X1(struct sFLYBACK_X1 *s, double KP, double KI, double KD) {
   s->stepped = false;
   s->t_prev = 0;
   init_pid(&(s->pid), KP, KI, KD);
}

extern "C" __declspec(dllexport) void flyback_x1(struct sFLYBACK_X1 **opaque, double t, union uData *data)
{
   double  SET   = data[0].d; // input
   double  CS    = data[1].d; // input
   double  VS    = data[2].d; // input
   bool    CLK   = data[3].b; // input
   double &DRIVE = data[4].d; // output

   double i_pri_max = 2;
   double i_pri_set = 0;
   const double err_i_pri_max_scaler = 0.01;

   if(!*opaque)
   {
      *opaque = (struct sFLYBACK_X1 *) malloc(sizeof(struct sFLYBACK_X1));
      // bzero(*opaque, sizeof(struct sFLYBACK_X1));
      init_sFLYBACK_X1(*opaque, 1.0, 0.0, 0.0);
   }
   struct sFLYBACK_X1 *inst = *opaque;

   double i_pri = 2*CS;

   if (CLK && !inst->stepped) {
      // evaluate PID step
      double dt = t - inst->t_prev;

      inst->pid.err[0] = inst->pid.err[1];
      inst->pid.err[1] = SET - VS;

      double P = inst->pid.err[1] * inst->pid.KP;
      inst->pid.I += (inst->pid.err[1] * dt) * inst->pid.KI;
      double D = ((inst->pid.err[1] - inst->pid.err[0]) / dt) * inst->pid.KD;
      
      double out = P + inst->pid.I + D;

      i_pri_max = (err_i_pri_max_scaler * out);

      inst->stepped = true;
      inst->t_prev = t;

      DRIVE = 1;
   } else if (!CLK && inst->stepped) {
      inst->stepped = false;
      DRIVE = 0;
   }

   if (i_pri > i_pri_max) {DRIVE = 0;}
   // else {DRIVE = 1;}

}

extern "C" __declspec(dllexport) void Destroy(struct sFLYBACK_X1 *inst)
{
   free(inst);
}
