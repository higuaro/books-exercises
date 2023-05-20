Saturday 20/05/23

Now I'm adding dates to these entries. More pressure to actually get this done.

I have covid and I feel like garbage, BUT I now understand what my error is, and 
OH MY LORD I'm soo stupid, I don't need to dispatch the PC to a kernel sub-section
they all should be executed in sequence, why did I ever think of that in the 
first place??

None of the kernels should jump back to the beginning of the scanline, just
need to sta WSYNC and let the next kernel do its part. Oh my God I'm such an...

Anyway! Let's try that, although, I don't feel like doing anything at the moment
to be honest. 
