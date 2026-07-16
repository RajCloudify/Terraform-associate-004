 removed {
        from = aws_vpc.main

        lifecycle {
          destroy = false
        }
      }

      removed {
        from = aws_subnet.app

        lifecycle {
          destroy = false
        }
      }

      removed {
        from = aws_security_group.app

        lifecycle {
          destroy = false
        }
      }